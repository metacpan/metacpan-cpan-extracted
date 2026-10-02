#!/usr/bin/env perl
# ABSTRACT: streamed tool calls arrive as the same ToolCall objects the non-streaming reply yields, on every dialect
use strict;
use warnings;

use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Path::Tiny;

use Langertha::Engine::AKIOpenAI;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Request::SyncHTTP;
use Langertha::Tool;

# karr k221: the Chat-Completions, Anthropic, Gemini and Ollama-native stream
# parsers read only text and thinking, so a streamed tool call was dropped on
# the floor and chat_stream_realtime_f ended as a silent, empty success -- a
# lost call quietly ends an agent loop. ADR 0003: Response.tool_calls is the one
# tool-call shape, so a stream must hand back the SAME Langertha::ToolCall the
# non-streaming reply of the same response produces, exactly once, built by
# ToolCall->extract (never by hand), and aggregate_tool_calls must find it.
#
# Source of truth for each finished call is a non-streaming reply read by
# chat_response: the verbatim AKI.IO captures (t/data/akiopenai_*,
# t/data/akianthropic_*) and the Ollama capture. No Gemini tool-call capture
# exists, so its reply follows the generateContent reference. The STREAMS are
# doc-derived, not captured: the event shapes follow each provider's streaming
# reference -- OpenAI Chat Completions chunk objects (delta.tool_calls with
# index-keyed function.arguments fragments), Anthropic Messages streaming
# (content_block_start tool_use + input_json_delta partial_json +
# content_block_stop), Gemini streamGenerateContent (whole functionCall parts)
# and Ollama /api/chat streaming (whole message.tool_calls) -- with the payload
# values taken from the capture, so fragments concatenate to its arguments.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub reply_calls {
  my ( $engine, $file_or_data ) = @_;
  my $body = ref $file_or_data ? $json->encode($file_or_data) : path($file_or_data)->slurp_raw;
  my $res = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $body );
  return [ map { $_->to_hash } @{ $engine->chat_response($res)->tool_calls // [] } ];
}

sub hashes { [ map { $_->to_hash } @{ $_[0] } ] }
sub sse    { join '', map { 'data: ' . $json->encode($_) . "\n\n" } @_ }
sub sse_ev { join '', map { "event: $_->{type}\ndata: " . $json->encode($_) . "\n\n" } @_ }
sub ndjson { join '', map { $json->encode($_) . "\n" } @_ }

# ---------------------------------------------------------------------------
# OpenAI Chat Completions: fragments assembled per index, delivered on the
# chunk that carries finish_reason.
# ---------------------------------------------------------------------------

my $oa_capture = $json->decode( path('t/data/akiopenai_tool_call_response.json')->slurp_raw );
my $oa_call    = $oa_capture->{choices}[0]{message}{tool_calls}[0];

sub openai_stream_events {
  my (%opt) = @_;
  my %base = ( id => $oa_capture->{id}, object => 'chat.completion.chunk',
    created => $oa_capture->{created}, model => $oa_capture->{model} );
  my $choice = sub { +{ %base, choices => [ { index => 0, @_ } ] } };
  return (
    $choice->( delta => { role => 'assistant', content => undef, tool_calls => [
      { index => 0, id => $oa_call->{id}, type => 'function',
        function => { name => 'add', arguments => '' } } ] }, finish_reason => undef ),
    $choice->( delta => { tool_calls => [ { index => 0, function => { arguments => '{"a": 7' } } ] },
      finish_reason => undef ),
    $choice->( delta => { tool_calls => [ { index => 0, function => { arguments => ', "b": 15}' } } ] },
      finish_reason => undef ),
    ( $opt{truncated} ? () : $choice->( delta => {}, finish_reason => $opt{finish} // 'stop' ) ),
  );
}

subtest 'OpenAI: one call, parity with the AKI.IO non-streaming capture' => sub {
  my $engine = Langertha::Engine::AKIOpenAI->new( api_key => 'k', model => 'llama3-chat-8b' );
  my $chunks = $engine->process_stream_data( sse( openai_stream_events() ) . "data: [DONE]\n\n" );
  my $tcs    = $engine->aggregate_tool_calls($chunks);

  is_deeply( hashes($tcs), reply_calls( $engine, 't/data/akiopenai_tool_call_response.json' ),
    'the streamed call equals the one chat_response reads off the capture' );
  is( scalar @$tcs, 1, 'delivered exactly once' );
  isa_ok( $tcs->[0], 'Langertha::ToolCall' );
  is_deeply( $tcs->[0]->arguments, { a => 7, b => 15 }, 'arguments assembled from the fragments' );
  ok( $chunks->[-1]->has_tool_calls, 'the call rides the finish_reason chunk' );
  ok( !( grep { $_->has_tool_calls } @$chunks[ 0 .. $#$chunks - 1 ] ), 'and no fragment chunk' );
  is( $chunks->[-1]->finish_reason, 'tool_calls', 'wire stop next to the call reports tool_calls (k248)' );
  is( $chunks->[-1]->finish_reason, $engine->chat_response( HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], path('t/data/akiopenai_tool_call_response.json')->slurp_raw ) )->finish_reason,
    'same finish_reason as the non-streaming reply' );
};

subtest 'OpenAI: parallel calls, fragments interleaved by index' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
  my $c = sub { +{ id => 'chatcmpl-1', model => 'gpt-4o-mini', choices => [ { index => 0, @_ } ] } };
  my $body = sse(
    $c->( delta => { role => 'assistant', tool_calls => [
      { index => 0, id => 'call_a', type => 'function', function => { name => 'get_weather', arguments => '' } } ] } ),
    $c->( delta => { tool_calls => [ { index => 0, function => { arguments => '{"city":' } } ] } ),
    $c->( delta => { tool_calls => [
      { index => 1, id => 'call_b', type => 'function', function => { name => 'get_time', arguments => '' } } ] } ),
    $c->( delta => { tool_calls => [ { index => 1, function => { arguments => '{"tz":"CET"}' } } ] } ),
    $c->( delta => { tool_calls => [ { index => 0, function => { arguments => '"Paris"}' } } ] } ),
    $c->( delta => {}, finish_reason => 'tool_calls' ),
  );
  my $reply = reply_calls( $engine, { id => 'chatcmpl-1', model => 'gpt-4o-mini', choices => [ {
    index => 0, finish_reason => 'tool_calls', message => { role => 'assistant', content => undef, tool_calls => [
      { id => 'call_a', type => 'function', function => { name => 'get_weather', arguments => '{"city":"Paris"}' } },
      { id => 'call_b', type => 'function', function => { name => 'get_time',    arguments => '{"tz":"CET"}' } },
    ] } } ] } );

  for my $path ( 'sync', 'buffer' ) {
    my $chunks;
    if ( $path eq 'sync' ) { $chunks = $engine->process_stream_data($body) }
    else {
      my $buffer = $body;
      $chunks = $engine->_process_stream_buffer( \$buffer, 'sse', 1, {} );
    }
    is_deeply( hashes( $engine->aggregate_tool_calls($chunks) ), $reply,
      "$path: both calls, in index order, equal to the non-streaming reply" );
    is( $chunks->[-1]->finish_reason, 'tool_calls', "$path: finish_reason tool_calls kept" );
  }
};

subtest 'OpenAI: stream state is per stream' => sub {
  my $engine = Langertha::Engine::AKIOpenAI->new( api_key => 'k', model => 'llama3-chat-8b' );

  # Two streams interleaved on one engine (what two concurrent
  # chat_stream_realtime_f calls do): each keeps its own fragments.
  my @events = openai_stream_events();
  my ( %one, %two );
  my ( @one, @two );
  for my $event (@events) {
    for ( [ \%one, \@one ], [ \%two, \@two ] ) {
      my ( $state, $out ) = @$_;
      my $buffer = sse($event);
      push @$out, @{ $engine->_process_stream_buffer( \$buffer, 'sse', 0, $state ) };
    }
  }
  is_deeply( hashes( $engine->aggregate_tool_calls( \@one ) ), hashes( $engine->aggregate_tool_calls( \@two ) ),
    'interleaved streams each assemble their own call' );
  is( scalar @{ $engine->aggregate_tool_calls( \@one ) }, 1, 'no fragment bleeds into the other stream' );

  # A stream cut off before finish_reason must not leak its fragments into the
  # next stream on the same engine. Its unfinished call is not flushed -- an
  # unterminated arguments string would decode to {} and run the tool with
  # made-up arguments -- but dropping it must be loud: one carp per stream
  # (review of k221, point 5).
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $engine->process_stream_data( sse( openai_stream_events( truncated => 1 ) ) );
  }
  is( scalar @warnings, 1, 'a truncated stream with an assembled call carps once' );
  like( $warnings[0] // '', qr/without a finish_reason.*1 unfinished tool call.*\badd\b/,
    'naming the dropped call' );
  my $next = $engine->process_stream_data( sse(
    { choices => [ { index => 0, delta => { content => 'hi' } } ] },
    { choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] } ) );
  ok( !( grep { $_->has_tool_calls } @$next ), 'a truncated stream leaves nothing behind' );

  # The same through the engine-wide fallback a direct caller gets when it
  # passes no state (review M1): the final flush ends the stream, so a stale
  # call cannot surface on the next stream's finish_reason chunk.
  @warnings = ();
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $cut = sse( openai_stream_events( truncated => 1 ) );
    $engine->_process_stream_buffer( \$cut, 'sse', 1 );
  }
  is( scalar @warnings, 1, 'fallback state: the truncated stream carps once at its final flush' );
  my $text = sse(
    { choices => [ { index => 0, delta => { content => 'hi' } } ] },
    { choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] } );
  my $after = $engine->_process_stream_buffer( \$text, 'sse', 1 );
  ok( !( grep { $_->has_tool_calls } @$after ), 'fallback state: no stale call on the next stream' );
};

subtest 'OpenAI: fragments without index' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
  my $c = sub { +{ choices => [ { index => 0, @_ } ] } };

  # Some OpenAI-compatible servers stream whole calls and omit `index` (review
  # I3; which ones is not verified). Keyed by position, the second call merged
  # into the first: one call, arguments "{..}{..}" decoded to {}. A fragment
  # without index is keyed by its id when it has one.
  my $body = sse(
    $c->( delta => { tool_calls => [ { id => 'call_a', type => 'function',
      function => { name => 'f', arguments => '{"x":1}' } } ] } ),
    $c->( delta => { tool_calls => [ { id => 'call_b', type => 'function',
      function => { name => 'g', arguments => '{"y":2}' } } ] } ),
    $c->( delta => {}, finish_reason => 'tool_calls' ) );
  is_deeply( hashes( $engine->aggregate_tool_calls( $engine->process_stream_data($body) ) ), [
    { name => 'f', arguments => { x => 1 }, id => 'call_a', synthetic => 0 },
    { name => 'g', arguments => { y => 2 }, id => 'call_b', synthetic => 0 },
  ], 'two index-less whole calls stay two calls, in stream order' );

  # An empty-string finish_reason on an intermediate chunk is no finish: it
  # must not flush the call before its arguments arrived (review M2).
  $body = sse(
    $c->( delta => { tool_calls => [ { index => 0, id => 'call_a', type => 'function',
      function => { name => 'f', arguments => '' } } ] }, finish_reason => '' ),
    $c->( delta => { tool_calls => [ { index => 0, function => { arguments => '{"x":1}' } } ] }, finish_reason => '' ),
    $c->( delta => {}, finish_reason => 'tool_calls' ) );
  my $chunks = $engine->process_stream_data($body);
  is_deeply( hashes( $engine->aggregate_tool_calls($chunks) ),
    [ { name => 'f', arguments => { x => 1 }, id => 'call_a', synthetic => 0 } ],
    'an empty finish_reason does not flush early' );
  ok( $chunks->[-1]->has_tool_calls, 'the call rides the real finish_reason chunk' );
  # Nor does it end the stream: a consumer that stops at is_final (the hermes
  # stream lift, k253) would otherwise finish before the text did (k253 review).
  ok( !( grep { $_->is_final } @{$chunks}[ 0 .. $#$chunks - 1 ] ),
    'a chunk with an empty finish_reason is not final' );
  ok( !( grep { $_->has_finish_reason } @{$chunks}[ 0 .. $#$chunks - 1 ] ),
    'and carries no finish_reason' );
  ok( $chunks->[-1]->is_final, 'the real finish_reason chunk is' );
};

# ---------------------------------------------------------------------------
# Anthropic Messages: a tool_use block assembled from input_json_delta,
# delivered on its content_block_stop.
# ---------------------------------------------------------------------------

my $an_capture = $json->decode( path('t/data/akianthropic_tool_call_response.json')->slurp_raw );
my $an_block   = $an_capture->{content}[0];

sub anthropic_stream_events {
  return (
    { type => 'message_start', message => { id => $an_capture->{id}, type => 'message', role => 'assistant',
      model => $an_capture->{model}, content => [], stop_reason => undef, usage => { input_tokens => 227 } } },
    { type => 'content_block_start', index => 0, content_block => { type => 'text', text => '' } },
    { type => 'content_block_delta', index => 0, delta => { type => 'text_delta', text => 'Adding.' } },
    { type => 'content_block_stop', index => 0 },
    { type => 'content_block_start', index => 1, content_block => {
      type => 'tool_use', id => $an_block->{id}, name => $an_block->{name}, input => {} } },
    { type => 'content_block_delta', index => 1, delta => { type => 'input_json_delta', partial_json => '' } },
    { type => 'content_block_delta', index => 1, delta => { type => 'input_json_delta', partial_json => '{"a": 7' } },
    { type => 'content_block_delta', index => 1, delta => { type => 'input_json_delta', partial_json => ', "b": 15}' } },
    { type => 'content_block_stop', index => 1 },
    { type => 'message_delta', delta => { stop_reason => 'tool_use', stop_sequence => undef },
      usage => { output_tokens => 23 } },
    { type => 'message_stop' },
  );
}

subtest 'Anthropic: tool_use block, parity with the AKI.IO /anthropic capture' => sub {
  my $engine = Langertha::Engine::AKIAnthropic->new( api_key => 'k', model => 'llama3-chat-8b' );
  my $chunks = $engine->process_stream_data( sse_ev( anthropic_stream_events() ) );
  my $tcs    = $engine->aggregate_tool_calls($chunks);

  is_deeply( hashes($tcs), reply_calls( $engine, 't/data/akianthropic_tool_call_response.json' ),
    'the streamed call equals the one chat_response reads off the capture' );
  is( scalar @$tcs, 1, 'delivered exactly once' );
  is_deeply( $tcs->[0]->arguments, { a => 7, b => 15 }, 'input assembled from partial_json' );
  my ($carrier) = grep { $_->has_tool_calls } @$chunks;
  is( $carrier->raw->{type}, 'content_block_stop', 'the call rides its content_block_stop' );
  is( join( '', map { $_->content } @$chunks ), 'Adding.', 'text unchanged' );
  ok( $chunks->[-1]->is_final, 'final chunk still message_stop' );
  is( $chunks->[-1]->finish_reason, 'tool_use', 'finish_reason tool_use as in the reply' );
};

subtest 'Anthropic: a tool_use with no input deltas keeps its start input' => sub {
  my $engine = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-8' );
  my $chunks = $engine->process_stream_data( sse_ev(
    { type => 'message_start', message => { id => 'm' } },
    { type => 'content_block_start', index => 0, content_block => {
      type => 'tool_use', id => 'toolu_1', name => 'ping', input => {} } },
    { type => 'content_block_stop', index => 0 },
    { type => 'message_stop' } ) );
  my $tcs = $engine->aggregate_tool_calls($chunks);
  is( scalar @$tcs, 1, 'one call' );
  is_deeply( $tcs->[0]->to_hash, { name => 'ping', arguments => {}, id => 'toolu_1', synthetic => 0 },
    'empty arguments, id kept' );
};

subtest 'Anthropic: terminal metadata is per stream' => sub {
  # k167 replays message_delta's finish_reason + usage onto the is_final
  # message_stop chunk. That carry was engine-wide, so a second stream's
  # message_start between the first stream's message_delta and message_stop
  # wiped the first stream's finish_reason and usage, and a second
  # message_delta handed the first stream the other's (review of k221, I2).
  # Two concurrent chat_stream_realtime_f on one engine do exactly this.
  my $engine = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-8' );
  my $feed = sub {
    my ( $state, @events ) = @_;
    my $buffer = sse_ev(@events);
    return @{ $engine->_process_stream_buffer( \$buffer, 'sse', 0, $state ) };
  };
  my ( %one, %two );
  $feed->( \%one, { type => 'message_start', message => { id => 'A' } },
    { type => 'message_delta', delta => { stop_reason => 'end_turn' }, usage => { output_tokens => 11 } } );
  $feed->( \%two, { type => 'message_start', message => { id => 'B' } },
    { type => 'message_delta', delta => { stop_reason => 'tool_use' }, usage => { output_tokens => 99 } } );
  my ($final_one) = $feed->( \%one, { type => 'message_stop' } );
  my ($final_two) = $feed->( \%two, { type => 'message_stop' } );
  is( $final_one->finish_reason, 'end_turn', 'stream A keeps its own finish_reason' );
  is( $final_one->usage->{output_tokens}, 11, 'and its own usage' );
  is( $final_two->finish_reason, 'tool_use', 'stream B keeps its own finish_reason' );
  is( $final_two->usage->{output_tokens}, 99, 'and its own usage' );

  # A direct caller that passes no state still gets the replay (engine-wide
  # fallback), as t/43_streaming_parser.t relies on.
  my $direct = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-8' );
  $direct->parse_stream_chunk( { type => 'message_start', message => { id => 'C' } } );
  $direct->parse_stream_chunk( { type => 'message_delta', delta => { stop_reason => 'max_tokens' } } );
  is( $direct->parse_stream_chunk( { type => 'message_stop' } )->finish_reason, 'max_tokens',
    'fallback state: replay still works for a direct caller' );
};

# ---------------------------------------------------------------------------
# Gemini: functionCall parts arrive whole, on the chunk that carries them.
# ---------------------------------------------------------------------------

subtest 'Gemini: functionCall parts' => sub {
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview' );
  my @parts = (
    { functionCall => { name => 'get_weather', args => { city => 'Paris' } } },
    { functionCall => { name => 'get_time', args => { tz => 'CET' } } },
  );
  my $reply = reply_calls( $engine, { candidates => [ { content => { role => 'model',
    parts => [ { text => 'Checking.' }, @parts ] }, finishReason => 'STOP' } ] } );
  my $chunks = $engine->process_stream_data( sse(
    { candidates => [ { content => { role => 'model', parts => [ { text => 'Checking.' } ] } } ] },
    { candidates => [ { content => { role => 'model', parts => [ @parts ] }, finishReason => 'STOP' } ],
      usageMetadata => { promptTokenCount => 5, candidatesTokenCount => 9, totalTokenCount => 14 } },
  ) );
  is_deeply( hashes( $engine->aggregate_tool_calls($chunks) ), $reply,
    'both calls equal the non-streaming reply' );
  ok( !$chunks->[0]->has_tool_calls, 'text chunk carries none' );
  ok( $chunks->[1]->has_tool_calls, 'the functionCall chunk carries them' );
  is( $chunks->[1]->finish_reason, 'STOP', 'finishReason as the provider sent it' );
};

# ---------------------------------------------------------------------------
# Ollama native: message.tool_calls arrive whole.
# ---------------------------------------------------------------------------

subtest 'Ollama native: message.tool_calls, parity with the capture' => sub {
  my $engine  = Langertha::Engine::Ollama->new( url => 'http://test.invalid:11434', model => 'qwen3:8b' );
  my $capture = $json->decode( path('t/data/ollama_tool_call_response.json')->slurp_raw );
  my $chunks  = $engine->process_stream_data( ndjson(
    { model => 'qwen3:8b', created_at => $capture->{created_at}, done => JSON->false,
      message => { role => 'assistant', content => '', tool_calls => $capture->{message}{tool_calls} } },
    { model => 'qwen3:8b', created_at => $capture->{created_at}, done => JSON->true, done_reason => 'stop',
      message => { role => 'assistant', content => '' }, eval_count => 228, prompt_eval_count => 153 },
  ) );
  my $tcs = $engine->aggregate_tool_calls($chunks);
  is_deeply( hashes($tcs), reply_calls( $engine, 't/data/ollama_tool_call_response.json' ),
    'the streamed call equals the one chat_response reads off the capture' );
  is( scalar @$tcs, 1, 'delivered exactly once' );
  ok( $chunks->[0]->has_tool_calls && !$chunks->[1]->has_tool_calls, 'on the chunk that carried it' );
  is( $chunks->[1]->finish_reason, 'stop', 'done_reason unchanged' );
};

subtest 'tools: the caller\'s order is kept' => sub {
  # Order is caller intent, and on Anthropic a cache_control breakpoint caches
  # the prefix of the tool list, so serializing Tool objects must not move them
  # ahead of the hashes (review of k221, M3). Gemini's function declarations
  # live in one functionDeclarations entry, placed where the first object was.
  my $obj  = Langertha::Tool->new( name => 'obj', input_schema => { type => 'object', properties => {} } );
  my $obj2 = Langertha::Tool->new( name => 'obj2', input_schema => { type => 'object', properties => {} } );
  my $hash = { type => 'function', function => { name => 'hash', parameters => { type => 'object', properties => {} } } };
  my $oa = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
  is_deeply( $oa->_wire_tools( [ $hash, $obj, $hash, $obj2 ] ),
    [ $hash, $obj->to('openai'), $hash, $obj2->to('openai') ], 'openai: every tool in place' );

  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview' );
  my $search = { google_search => {} };
  is_deeply( $gemini->_wire_tools( [ $search, $obj, $obj2 ] ),
    [ $search, @{ Langertha::Tool->format_list( 'gemini', [ $obj, $obj2 ] ) } ],
    'gemini: objects grouped into one functionDeclarations entry at the first object' );
};

{
  # Records the tools chat_stream_realtime_f hands to chat_stream_request and
  # stops there: the claim is the request body, not the transport.
  package Test::StopAtStreamRequest;
  use Moose::Role;
  has seen_tools => ( is => 'rw' );
  around chat_stream_request => sub {
    my ( $orig, $self, $messages, %extra ) = @_;
    $self->seen_tools( $extra{tools} );
    die "stop before sending\n";
  };
}

subtest 'tools: chat_stream_realtime_f shapes them per item, as chat_f (k227 review M4)' => sub {
  # k227: the streaming path goes through the same Tool->request_list as
  # chat_f, so an MCP hash is converted rather than sent in a shape the wire
  # rejects, and Gemini gets ONE functionDeclarations entry.
  my $schema = { type => 'object', properties => { q => { type => 'string' } } };
  my $mcp  = { name => 'mcp', description => 'An MCP tool', inputSchema => $schema };
  my $obj  = Langertha::Tool->new( name => 'obj', input_schema => $schema );
  my $stop = sub {
    my ( $engine, @tools ) = @_;
    ok( !eval { $engine->chat_stream_realtime_f( messages => ['hi'], tools => \@tools )->get; 1 },
      'stopped at chat_stream_request' );
    is( $@, "stop before sending\n", 'for the recording stop, not an earlier croak' );
    return $engine->seen_tools;
  };

  my $oa = Moose::Util::with_traits( 'Langertha::Engine::OpenAI', 'Test::StopAtStreamRequest' )
    ->new( api_key => 'k', model => 'gpt-4o-mini' );
  is_deeply( $stop->( $oa, $mcp ), [ Langertha::Tool->from_hash($mcp)->to('openai') ],
    'openai: an MCP hash is converted' );

  my $gemini = Moose::Util::with_traits( 'Langertha::Engine::Gemini', 'Test::StopAtStreamRequest' )
    ->new( api_key => 'k', model => 'gemini-3-flash-preview' );
  my $raw = { functionDeclarations => [ { name => 'raw', parameters => $schema } ] };
  is_deeply( $stop->( $gemini, { google_search => {} }, $obj, $raw, $mcp ),
    [ { google_search => {} },
      { functionDeclarations => [ $obj->to('gemini'), $raw->{functionDeclarations}[0],
          Langertha::Tool->from_hash($mcp)->to('gemini') ] } ],
    'gemini: object, raw entry and MCP hash merged into one functionDeclarations entry' );
};

# ---------------------------------------------------------------------------
# Across the real transport (ADR 0027): chat_stream_realtime_f over the sync
# LWP shim and Net::Async::HTTP against a local daemon. The engines record the
# request body they built, so the same run checks that canonical Tool objects
# reach the wire serialized for the engine's tool_wire_format, while a tool
# hash (already the caller's wire shape) passes through untouched.
# ---------------------------------------------------------------------------

{
  package Test::RecordingOpenAI;
  use Moose;
  extends 'Langertha::Engine::AKIOpenAI';
  has sent => ( is => 'rw' );
  around chat_stream_request => sub {
    my ( $orig, $self, @args ) = @_;
    my $request = $self->$orig(@args);
    $self->sent( JSON::MaybeXS->new( utf8 => 1 )->decode( $request->content ) );
    return $request;
  };
  __PACKAGE__->meta->make_immutable;
}
{
  package Test::RecordingAnthropic;
  use Moose;
  extends 'Langertha::Engine::AKIAnthropic';
  has sent => ( is => 'rw' );
  around chat_stream_request => sub {
    my ( $orig, $self, @args ) = @_;
    my $request = $self->$orig(@args);
    $self->sent( JSON::MaybeXS->new( utf8 => 1 )->decode( $request->content ) );
    return $request;
  };
  __PACKAGE__->meta->make_immutable;
}

SKIP: {
  skip 'fork-based HTTP::Daemon test not supported on Windows', 1 if $^O eq 'MSWin32';
  require Test::LocalHTTPDaemon;

  my $server = Test::LocalHTTPDaemon->start( sub {
    my ($request) = @_;
    my @events = $request->uri->path =~ m{/v1/messages\z}
      ? ( map { sse_ev($_) } anthropic_stream_events() )
      : ( ( map { sse($_) } openai_stream_events() ), "data: [DONE]\n\n" );
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
      return shift(@events) // '';
    } );
  } );
  my $base = $server->url;

  my @backends = ( [ 'sync LWP shim', sub {
    ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) ) } ] );
  push @backends, [ 'Net::Async::HTTP', sub { () } ]
    if eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };

  my $tool = Langertha::Tool->new( name => 'add', description => 'Add two numbers',
    input_schema => { type => 'object', properties => { a => { type => 'number' }, b => { type => 'number' } } } );
  my $server_tool = { type => 'web_search_20250305', name => 'web_search', max_uses => 1 };
  my $cached_tool  = { name => 'mul', input_schema => { type => 'object', properties => {} },
    cache_control => { type => 'ephemeral' } };

  for my $backend (@backends) {
    my ( $label, $args ) = @$backend;
    subtest "$label: chat_stream_realtime_f" => sub {
      my $oa = Test::RecordingOpenAI->new( api_key => 'k', model => 'llama3-chat-8b',
        url => "$base/v1", $args->() );
      my ( $content, $chunks ) = $oa->chat_stream_realtime_f(
        messages => ['add 7 and 15'], tools => [$tool] )->get;
      is_deeply( hashes( $oa->aggregate_tool_calls($chunks) ),
        reply_calls( $oa, 't/data/akiopenai_tool_call_response.json' ), 'OpenAI: streamed call matches the reply' );
      is_deeply( $oa->sent->{tools}, Langertha::Tool->format_list( 'openai', [$tool] ),
        'OpenAI: a canonical Tool goes on the wire in the openai shape' );

      my $an = Test::RecordingAnthropic->new( api_key => 'k', model => 'llama3-chat-8b',
        url => $base, $args->() );
      ( $content, $chunks ) = $an->chat_stream_realtime_f(
        messages => ['add 7 and 15'], tools => [ $server_tool, $tool, $cached_tool ] )->get;
      is_deeply( hashes( $an->aggregate_tool_calls($chunks) ),
        reply_calls( $an, 't/data/akianthropic_tool_call_response.json' ), 'Anthropic: streamed call matches the reply' );
      is( $content, 'Adding.', 'Anthropic: text still streams' );
      is_deeply( $an->sent->{tools},
        [ $server_tool, @{ Langertha::Tool->format_list( 'anthropic', [$tool] ) }, $cached_tool ],
        'Anthropic: a canonical Tool is serialized in place; wire-shaped hashes (a built-in, '
        . 'cache_control) pass through untouched and the caller\'s order is kept' );
    };
  }
}

done_testing;
