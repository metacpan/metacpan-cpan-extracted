#!/usr/bin/env perl
# ABSTRACT: An OpenAI-compatible reply that carries tool calls reports finish_reason tool_calls, even when the wire says stop

use strict;
use warnings;

use Test2::Bundle::More;
use HTTP::Response;
use JSON::MaybeXS;
use Path::Tiny qw( path );

use Langertha::Engine::AKIOpenAI;
use Langertha::Engine::OpenAI;

# karr k248, ADR 0018 (dialect tier). gpt-oss served by vLLM-style stacks --
# seen live on AKI.IO's OpenAI-compatible endpoint, gpt-oss-120b, 2026-09-25 --
# answers a tool call with finish_reason "stop" instead of "tool_calls" on the
# non-streaming path (the stream of the same request said "tool_calls"). A
# caller that branches on finish_reason (a proxy re-emitting the reply in
# another dialect maps stop to end_turn, an agent loop that stops on "stop")
# would treat a pending tool call as a finished answer. Response.tool_calls is
# the one tool-call shape (ADR 0003), so the dialect reports the finish that
# matches it: a reply WITH tool calls and wire finish "stop" reports
# "tool_calls" -- the same rule ResponsesCompatible applies (k171). Only
# "stop" is rewritten: "length" means the reply was cut off and must stay
# visible; a reply without tool calls keeps "stop". The wire value stays
# readable on ->raw.

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub fixture_http {
  my ($name) = @_;
  my $headers = $json->decode( $data_dir->child("$name.headers.json")->slurp_raw );
  return HTTP::Response->new( 200, 'OK', [ %$headers ], $data_dir->child("$name.json")->slurp_raw );
}

sub reply_http {
  my ($data) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode($data) );
}

sub sse { join '', map { 'data: ' . $json->encode($_) . "\n\n" } @_ }

my $call = { id => 'call_1', type => 'function',
  function => { name => 'add', arguments => '{"a":7,"b":15}' } };

sub reply {
  my (%opt) = @_;
  return { id => 'chatcmpl-1', model => 'gpt-oss-120b', choices => [ {
    index => 0,
    exists $opt{finish} ? ( finish_reason => $opt{finish} ) : (),
    message => { role => 'assistant', content => $opt{content},
      $opt{calls} ? ( tool_calls => [ $call ] ) : () },
  } ] };
}

my $engine = Langertha::Engine::AKIOpenAI->new( api_key => 'k', model => 'gpt-oss-120b' );

subtest 'verbatim AKI.IO gpt-oss-120b capture: stop with a tool call' => sub {
  my $resp = eval { $engine->chat_response( fixture_http('akiopenai_gptoss_tool_call_response') ) };
  ok( defined $resp, 'Response constructed' ) or diag($@);
  is( $resp->raw->{choices}[0]{finish_reason}, 'stop', 'the wire said stop' );
  is( scalar @{ $resp->tool_calls }, 1, 'one tool call on Response.tool_calls' );
  is( $resp->tool_call('add')->arguments->{b}, 15, 'the call is intact' );
  is( $resp->finish_reason, 'tool_calls', 'finish_reason reports the tool call' );
};

subtest 'verbatim AKI.IO llama3-chat-8b capture (k102): same quirk' => sub {
  my $e = Langertha::Engine::AKIOpenAI->new( api_key => 'k', model => 'llama3-chat-8b' );
  my $resp = $e->chat_response( fixture_http('akiopenai_tool_call_response') );
  is( $resp->raw->{choices}[0]{finish_reason}, 'stop', 'the wire said stop' );
  is( $resp->finish_reason, 'tool_calls', 'finish_reason reports the tool call' );
};

subtest 'only stop-with-tool-calls is rewritten' => sub {
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
  my @cases = (
    [ 'text + tool call, stop',   { calls => 1, finish => 'stop', content => 'Let me add.' }, 'tool_calls' ],
    [ 'tool call, tool_calls',    { calls => 1, finish => 'tool_calls' },                    'tool_calls' ],
    [ 'tool call, length',        { calls => 1, finish => 'length' },                        'length' ],
    [ 'tool call, content_filter',{ calls => 1, finish => 'content_filter' },                'content_filter' ],
    [ 'text only, stop',          { finish => 'stop', content => 'Hi' },                     'stop' ],
  );
  for my $case (@cases) {
    my ( $label, $opt, $want ) = @$case;
    is( $openai->chat_response( reply_http( reply(%$opt) ) )->finish_reason, $want, $label );
  }
  my $absent = $openai->chat_response( reply_http( reply( calls => 1 ) ) );
  ok( !$absent->has_finish_reason, 'no wire finish_reason: none invented' );
};

subtest 'verbatim AKI.IO gpt-oss-120b stream: tool_calls kept' => sub {
  my $chunks = $engine->process_stream_data( $data_dir->child('akiopenai_gptoss_tool_call_stream.sse')->slurp_raw );
  my $tcs    = $engine->aggregate_tool_calls($chunks);
  is( scalar @$tcs, 1, 'one streamed tool call' );
  is_deeply( $tcs->[0]->arguments, { a => 7, b => 15 }, 'arguments assembled' );
  my ($final) = grep { $_->has_finish_reason } @$chunks;
  is( $final->finish_reason, 'tool_calls', 'finish_reason tool_calls' );
};

subtest 'stream parity: stop with tool calls reports tool_calls' => sub {
  my $c = sub { +{ id => 'chatcmpl-1', model => 'gpt-oss-120b', choices => [ { index => 0, @_ } ] } };
  my $events = sub {
    my ( $finish, $with_call ) = @_;
    return sse(
      ( $with_call
        ? ( $c->( delta => { tool_calls => [ { index => 0, id => 'call_1', type => 'function',
              function => { name => 'add', arguments => '{"a":7,' } } ] }, finish_reason => undef ),
            $c->( delta => { tool_calls => [ { index => 0, function => { arguments => '"b":15}' } } ] },
              finish_reason => undef ) )
        : $c->( delta => { content => 'Hi' }, finish_reason => undef ) ),
      $c->( delta => {}, finish_reason => $finish ),
    ) . "data: [DONE]\n\n";
  };
  for my $case ( [ 'stop', 1, 'tool_calls' ], [ 'length', 1, 'length' ], [ 'stop', 0, 'stop' ] ) {
    my ( $wire, $with_call, $want ) = @$case;
    my $chunks = $engine->process_stream_data( $events->( $wire, $with_call ) );
    my $final  = $chunks->[-1];
    is( $final->finish_reason, $want, "wire $wire, " . ( $with_call ? 'with' : 'no' ) . " tool call: $want" );
    is( $final->raw->{choices}[0]{finish_reason}, $wire, '  raw keeps the wire value' );
    my $nonstream = $engine->chat_response( reply_http( reply(
      finish => $wire, $with_call ? ( calls => 1 ) : ( content => 'Hi' ) ) ) );
    is( $final->finish_reason, $nonstream->finish_reason, '  same as chat_response' );
  }
};

done_testing;
