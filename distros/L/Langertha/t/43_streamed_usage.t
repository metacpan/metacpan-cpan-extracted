#!/usr/bin/env perl
# ABSTRACT: A stream's token usage survives on every dialect: Anthropic message_start input, the OpenAI include_usage frame, Groq's x_groq.usage

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny qw( path );

use Langertha::Usage;
use Langertha::Engine::Anthropic;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Groq;

# karr k298. Streamed usage feeds Langertha::Usage, Pricing and Cost; a stream
# that loses half its counts undercounts what a call costs, silently.
#  - Anthropic reports the input side (input_tokens, cache_read/creation) only
#    on message_start and documents message_delta's usage as output_tokens only;
#    the final chunk carried input_tokens 0 and no cache counts.
#  - OpenAI's stream_options.include_usage (also vLLM / SGLang) sends the usage
#    in its own frame with choices [] AFTER the finish chunk; it was dropped.
#  - Groq puts the stream's usage under x_groq.usage; it was never read.
# Normalize, don't gatekeep (ADR 0018): every documented place is read.
# The fixtures are shaped from each provider's streaming documentation
# (Anthropic messages-streaming, OpenAI chat streaming, Groq API reference),
# with cache counts added; they are NOT verbatim live captures.

my $data_dir = path(__FILE__)->parent->child('data');
sub fixture { $data_dir->child(shift)->slurp_raw }

sub stream {
  my ( $engine, $name, $state ) = @_;
  my $buf = fixture($name);
  return $engine->_process_stream_buffer( \$buf, 'sse', 1, $state // {} );
}

subtest 'Anthropic: message_start usage merges into the final chunk' => sub {
  my $engine = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6' );
  my $chunks = stream( $engine, 'anthropic_stream_usage_doc.sse' );
  my ($final) = grep { $_->is_final } @$chunks;
  ok $final && $final->has_usage, 'final chunk carries usage';
  my $u = Langertha::Usage->from_hash( $final->usage );
  is $u->input_tokens,  25,   'input_tokens from message_start';
  is $u->output_tokens, 15,   'output_tokens from message_delta wins over message_start\'s 1';
  is $u->cached_tokens, 2000, 'cache reads from message_start';
  is $final->model, 'claude-sonnet-4-6', 'final chunk names the model';
  is_deeply $engine->aggregate_usage($chunks), $final->usage, 'aggregate_usage finds it';
  is $final->finish_reason, 'end_turn', 'finish_reason still on the final chunk';

  # message_delta repeating cumulative input counts wins key by key
  my $json = JSON::MaybeXS->new( canonical => 1 );
  my $buf = join '', map { "data: " . $json->encode($_) . "\n\n" }
    { type => 'message_start', message => { model => 'm', usage => { input_tokens => 5, cache_read_input_tokens => 7, output_tokens => 1 } } },
    { type => 'message_delta', delta => { stop_reason => 'end_turn' }, usage => { input_tokens => 6, output_tokens => 9 } },
    { type => 'message_stop' };
  my ($f2) = grep { $_->is_final } @{ $engine->_process_stream_buffer( \$buf, 'sse', 1, {} ) };
  is_deeply { map { $_ => $f2->usage->{$_} } qw( input_tokens cache_read_input_tokens output_tokens ) },
    { input_tokens => 6, cache_read_input_tokens => 7, output_tokens => 9 },
    'delta keys win, start-only keys survive';
};

subtest 'Anthropic: two interleaved streams on one engine keep their own usage' => sub {
  my $engine = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6' );
  my ( %sa, %sb );
  my $feed = sub { my ( $data, $st ) = @_; $engine->parse_stream_chunk( $data, undef, $st ) };
  $feed->( { type => 'message_start', message => { model => 'a', usage => { input_tokens => 100 } } }, \%sa );
  $feed->( { type => 'message_start', message => { model => 'b', usage => { input_tokens => 200 } } }, \%sb );
  $feed->( { type => 'message_delta', delta => { stop_reason => 'end_turn' }, usage => { output_tokens => 1 } }, \%sa );
  $feed->( { type => 'message_delta', delta => { stop_reason => 'end_turn' }, usage => { output_tokens => 2 } }, \%sb );
  my $fa = $feed->( { type => 'message_stop' }, \%sa );
  my $fb = $feed->( { type => 'message_stop' }, \%sb );
  is_deeply [ $fa->usage->{input_tokens}, $fa->model ], [ 100, 'a' ], 'stream a keeps its input and model';
  is_deeply [ $fb->usage->{input_tokens}, $fb->model ], [ 200, 'b' ], 'stream b keeps its input and model';
};

subtest 'OpenAI: the include_usage frame after the finish chunk is kept' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
  my $chunks = stream( $engine, 'openai_stream_include_usage_doc.sse' );
  is scalar @$chunks, 4, 'the usage-only frame yields a chunk';
  my $last = $chunks->[-1];
  ok !$last->is_final, 'the usage chunk is not a second final chunk';
  is $last->content, '', 'the usage chunk has no content';
  is $last->usage->{prompt_tokens}, 1200, 'it carries the usage';
  is $last->cached_tokens, 1024, 'and the cached_tokens detail';
  is scalar( grep { $_->is_final } @$chunks ), 1, 'exactly one final chunk';
  is join( '', map { $_->content } @$chunks ), 'Hello', 'content unchanged';
  my $u = Langertha::Usage->from_hash( $engine->aggregate_usage($chunks) );
  is_deeply [ $u->input_tokens, $u->output_tokens ], [ 1200, 2 ], 'aggregate_usage returns the stream usage';
  is $engine->parse_stream_chunk( { choices => [] }, undef, {} ), undef,
    'an empty choices frame without usage still yields nothing';
};

subtest 'Groq: x_groq.usage on the finish chunk is read' => sub {
  my $engine = Langertha::Engine::Groq->new( api_key => 'k', model => 'llama-3.3-70b-versatile' );
  my $chunks = stream( $engine, 'groq_stream_x_groq_doc.sse' );
  my ($final) = grep { $_->is_final } @$chunks;
  ok $final->has_usage, 'final chunk carries the x_groq usage';
  is $final->usage->{prompt_tokens}, 40, 'prompt_tokens from x_groq.usage';
  is $final->finish_reason, 'stop', 'the rest of the chunk is intact';
  ok !$chunks->[0]->has_usage, 'x_groq without usage adds nothing';

  my $both = $engine->parse_stream_chunk( { choices => [ { delta => {}, finish_reason => 'stop' } ],
    usage => { prompt_tokens => 1 }, x_groq => { usage => { prompt_tokens => 99 } } }, undef, {} );
  is $both->usage->{prompt_tokens}, 1, 'a top-level usage wins over x_groq.usage';

  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
  ok !( grep { $_->has_usage } @{ stream( $openai, 'groq_stream_x_groq_doc.sse' ) } ),
    'x_groq is read on Groq only (engine tier)';
};

done_testing;
