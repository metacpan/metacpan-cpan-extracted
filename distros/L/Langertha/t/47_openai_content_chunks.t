#!/usr/bin/env perl
# ABSTRACT: An OpenAI-compatible message.content / delta.content that is a list of content chunks reads into content + thinking

use strict;
use warnings;

use Test2::Bundle::More;
use HTTP::Response;
use JSON::MaybeXS;
use Path::Tiny qw( path );

use Langertha::Engine::Mistral;
use Langertha::Engine::OpenAI;

# karr k296, ADR 0018 (dialect tier). Mistral's reasoning models (Magistral,
# or any model called with reasoning_effort) answer /v1/chat/completions with
# message.content as a LIST of chunks -- a thinking chunk whose `thinking` is
# itself a list of text chunks, then a text chunk -- and stream delta.content
# as such a list during the thinking phase before switching to plain strings.
# Response.content and Stream::Chunk.content are Str, so the list died in the
# constructor ("Validation failed for 'Str' with value ARRAY") and the whole
# chat call was lost. Normalize, don't gatekeep: the text chunks are the
# answer, the thinking chunks are the chain-of-thought, any other chunk type
# carries no answer text and is skipped without a croak.
#
# The two fixtures are shaped from Mistral's reasoning documentation
# (docs.mistral.ai/capabilities/reasoning, read 2026-09-25) plus an unknown
# `reference` chunk; they are NOT verbatim live captures (no approved live call).

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub http_ok {
  my ($body) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $body );
}

my $mistral = Langertha::Engine::Mistral->new( api_key => 'k', model => 'magistral-medium-latest' );

subtest 'non-streaming: content chunks split into content and thinking' => sub {
  my $r = $mistral->chat_response(
    http_ok( $data_dir->child('mistral_magistral_doc_response.json')->slurp_raw ) );
  is $r->content,  '2 + 2 = **4**', 'text chunks become content (reference chunk skipped)';
  is $r->thinking, 'Okay, the user wants 2 + 2. That is 4.', 'nested thinking text chunks become thinking';
  is $r->finish_reason, 'stop', 'finish_reason read as usual';
  is ref $r->raw->{choices}[0]{message}{content}, 'ARRAY', 'the wire list stays on raw';
};

subtest 'non-streaming: the edges of the chunk list' => sub {
  my $reply = sub {
    my (%msg) = @_;
    http_ok( $json->encode( { choices => [ { finish_reason => 'stop',
      message => { role => 'assistant', %msg } } ] } ) );
  };
  my $r = $mistral->chat_response( $reply->( content => [
    'plain ', { type => 'text', text => 'string' }, { type => 'image_url', image_url => 'x' },
    { type => 'thinking', thinking => 'bare string thought' }, { type => 'mystery' }, undef, [ 'odd' ],
  ] ) );
  is $r->content,  'plain string', 'bare strings and text chunks join, unknown shapes are skipped';
  is $r->thinking, 'bare string thought', 'a thinking chunk with a string body is read too';

  $r = $mistral->chat_response( $reply->( reasoning_content => 'native',
    content => [ { type => 'thinking', thinking => [ { type => 'text', text => 'chunk' } ] },
                 { type => 'text', text => 'answer' } ] ) );
  is $r->thinking, 'native', 'reasoning_content keeps precedence over thinking chunks';
  is $r->content, 'answer', 'content still read from the list';

  $r = $mistral->chat_response( $reply->( content => [ { type => 'text', text => 'only text' } ] ) );
  ok !$r->has_thinking, 'no thinking chunk leaves thinking unset';

  $r = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' )
    ->chat_response( $reply->( content => 'a plain string' ) );
  is $r->content, 'a plain string', 'string content is unchanged';
};

subtest 'streaming: list deltas, then plain strings' => sub {
  my $buf    = $data_dir->child('mistral_magistral_doc_stream.sse')->slurp_raw;
  my $chunks = $mistral->_process_stream_buffer( \$buf, 'sse', 1, {} );
  is scalar @$chunks, 5, 'every event yields a chunk';
  is join( '', map { $_->content } @$chunks ), '2 + 2 = **4**', 'streamed content is the text chunks and strings';
  is $mistral->aggregate_thinking($chunks), 'Okay, the user wants 2 + 2. That is 4.',
    'streamed thinking chunks aggregate into the thinking';
  ok $chunks->[-1]->is_final, 'the finish chunk is final';

  my $one = $mistral->_process_stream_buffer( \( my $b =
    'data: ' . $json->encode( { choices => [ { index => 0,
      delta => { content => [ { type => 'mystery', x => 1 } ] } } ] } ) . "\n\n" ), 'sse', 1, {} );
  is $one->[0]->content, '', 'an unknown chunk type streams as empty content, no croak';
};

done_testing;
