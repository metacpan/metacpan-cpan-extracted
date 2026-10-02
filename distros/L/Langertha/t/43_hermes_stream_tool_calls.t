#!/usr/bin/env perl
# ABSTRACT: A streamed hermes tool turn withholds the call markup and puts the calls on the final chunk
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use lib 't/lib';
use Test::MockAsyncHTTP;
use Langertha::Engine::NousResearch;
use Langertha::Engine::OpenAI;
use Langertha::Engine::AKI;

# On a hermes engine (NousResearch; AKI native has no streaming) the tools ride
# the system prompt and the model answers with <tool_call> blocks in its text.
# chat_f lifts them onto Response.tool_calls (k231, ADR 0003); a streamed turn
# must do the same or a relay (knarr k19) and aggregate_tool_calls see no call
# and the markup reaches the user as text. Emitted text is gone once it is
# emitted, so the splitter has to hold back a tag split across chunks at any
# position. Unclosed markup is text: nothing the model wrote may be lost.
# -- karr k253, ADR 0001 (k253 Update)

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

{
  # Drives the on_header streaming callback with one SSE event per delta.
  package MockSSEHTTP;
  use Future;
  use HTTP::Response;
  sub new { my ( $class, @events ) = @_; bless { events => \@events }, $class }
  sub do_request {
    my ( $self, %args ) = @_;
    my $body = $args{on_header}->( HTTP::Response->new( 200, 'OK' ) );
    $body->($_) for @{ $self->{events} };
    $body->(undef);
    return Future->done( HTTP::Response->new( 200, 'OK' ) );
  }
}

sub sse {
  my ( $deltas, %opt ) = @_;
  my @events = map {
    'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => $_ } } ] }) . "\n\n"
  } @$deltas;
  unless ( $opt{truncated} ) {
    push @events, 'data: ' . $json->encode({ choices => [ { index => 0, delta => {},
      finish_reason => 'stop' } ] }) . "\n\n", "data: [DONE]\n\n";
  }
  return @events;
}

my $TOOL = { name => 'get_weather', description => 'Weather for a city',
  inputSchema => { type => 'object', properties => { city => { type => 'string' } } } };

sub nous { Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B', @_ ) }

# Runs one streamed turn; returns the text the callback saw, the chunks,
# the aggregated content and thinking.
sub stream_turn {
  my ( $engine_args, $deltas, %opt ) = @_;
  my $engine = nous( @$engine_args, _async_http => MockSSEHTTP->new( sse( $deltas, %opt ) ) );
  my $seen = '';
  my ( $content, $chunks, undef, $thinking ) = $engine->chat_stream_realtime_f(
    messages       => ['weather?'],
    chunk_callback => sub { $seen .= $_[0]->content },
    ( $opt{no_tools} ? () : ( tools => [$TOOL] ) ),
    ( $opt{tool_choice} ? ( tool_choice => $opt{tool_choice} ) : () ),
  )->get;
  return { seen => $seen, chunks => $chunks, content => $content, thinking => $thinking,
    calls => $engine->aggregate_tool_calls($chunks), engine => $engine };
}

# chat_f on the same reply text, for parity.
sub chat_f_turn {
  my ( $engine_args, $text ) = @_;
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({ choices => [ { index => 0,
      message => { role => 'assistant', content => $text }, finish_reason => 'stop' } ] }),
  ]);
  return nous( @$engine_args, _async_http => $mock )
    ->chat_f( messages => ['weather?'], tools => [$TOOL] )->get;
}

sub call_list { [ map { [ $_->name, $_->arguments ] } @{ $_[0] } ] }

my $CALL  = '<tool_call>{"name":"get_weather","arguments":{"city":"Berlin"}}</tool_call>';
my $REPLY = "Sure. ${CALL}\nDone.";

subtest 'a call tag split at every position streams only the text around it' => sub {
  my $parity = chat_f_turn( [], $REPLY );
  for my $at ( 1 .. length($REPLY) - 1 ) {
    my $r = stream_turn( [], [ substr( $REPLY, 0, $at ), substr( $REPLY, $at ) ] );
    is( $r->{seen}, "Sure. \nDone.", "split at $at: no markup reaches the callback" )
      or last;
    is_deeply( call_list( $r->{calls} ), [ [ get_weather => { city => 'Berlin' } ] ],
      "split at $at: the call is on the chunks" ) or last;
    is( $r->{content}, $parity->content, "split at $at: content as chat_f's" ) or last;
  }
  is_deeply( call_list( $parity->tool_calls ), [ [ get_weather => { city => 'Berlin' } ] ],
    'chat_f finds the same call' );
};

subtest 'one character per chunk; the calls land on the final chunk only' => sub {
  my $r = stream_turn( [], [ split //, $REPLY ] );
  is( $r->{seen}, "Sure. \nDone.", 'text outside the tag streams' );
  my @with_calls = grep { $_->has_tool_calls } @{ $r->{chunks} };
  is( scalar @with_calls, 1, 'one chunk carries calls' );
  ok( $with_calls[0]->is_final, 'the final one' );
  is( $with_calls[0]->finish_reason, 'tool_calls', "finish_reason is 'tool_calls'" );
  ok( !( grep { !$_->is_final && $_->content eq '' } @{ $r->{chunks} } ),
    'chunks that carried only call markup are not delivered' );
};

subtest 'several calls, in order' => sub {
  my $text = 'A<tool_call>{"name":"one","arguments":{"n":1}}</tool_call>B'
    . '<tool_call>{"name":"two","arguments":{"n":2}}</tool_call>C';
  my $r = stream_turn( [], [ $text =~ /(.{1,5})/sg ] );
  is( $r->{seen}, 'ABC', 'both blocks withheld' );
  is_deeply( call_list( $r->{calls} ), [ [ one => { n => 1 } ], [ two => { n => 2 } ] ], 'both calls' );
  is_deeply( call_list( $r->{calls} ), call_list( chat_f_turn( [], $text )->tool_calls ),
    'as chat_f finds them' );
};

subtest 'hermes_call_tag is honoured' => sub {
  my $text = 'x<function_call>{"name":"f","arguments":{}}</function_call>y<tool_call>z</tool_call>';
  my $r = stream_turn( [ hermes_call_tag => 'function_call' ], [ $text =~ /(.{1,3})/sg ] );
  is( $r->{seen}, 'xy<tool_call>z</tool_call>', 'the configured tag is withheld, the default is text' );
  is_deeply( call_list( $r->{calls} ), [ [ f => {} ] ], 'the call of the configured tag' );
};

subtest 'unclosed or partial markup is text, no call' => sub {
  my $open = 'Hi <tool_call>{"name":"get_weather","argu';
  my $r = stream_turn( [], [ $open =~ /(.{1,4})/sg ] );
  is( $r->{seen}, $open, 'an unclosed block is emitted at the end' );
  is_deeply( $r->{calls}, [], 'no call' );
  is( $r->{chunks}[-1]->finish_reason, 'stop', 'finish_reason stays' );

  $r = stream_turn( [], [ 'Hi <tool', '_ca' ] );
  is( $r->{seen}, 'Hi <tool_ca', 'a partial opening tag is emitted at the end' );

  # A closed block that carries no call is text the model wrote: it is
  # decided when it closes and streamed in place, and chat_f keeps it in
  # content likewise (k253 review I1).
  for my $case (
    [ 'invalid JSON'    => "Hi <tool_call>not json</tool_call> there$CALL!" ],
    [ 'no name'         => "Hi <tool_call>{\"arguments\":{}}</tool_call> there$CALL!" ],
    [ 'nested open tag' => "Hi <tool_call>a<tool_call>{\"name\":\"x\",\"arguments\":{}}</tool_call>b</tool_call>$CALL!" ],
  ) {
    my ( $name, $text ) = @$case;
    my $parity = chat_f_turn( [], $text );
    ( my $expect = $text ) =~ s/\Q$CALL\E//;
    for my $size ( 1, 4, length $text ) {
      $r = stream_turn( [], [ $text =~ /(.{1,$size})/sg ] );
      is( $r->{seen}, $expect, "$name, size $size: the block streams as text, in place" );
      is( $r->{content}, $parity->content, "$name, size $size: content as chat_f's" );
      is_deeply( call_list( $r->{calls} ), call_list( $parity->tool_calls ),
        "$name, size $size: calls as chat_f's" );
    }
    is_deeply( call_list( $parity->tool_calls ), [ [ get_weather => { city => 'Berlin' } ] ],
      "$name: only the real call is a call" );
  }
};

subtest 'a closed bad-args block carries arguments_undecodable, as chat_f' => sub {
  # A closed <tool_call> whose arguments are not an object IS a call (it has a
  # name): the non-streaming lift flags it arguments_undecodable so the tool
  # loop answers the model an error result rather than running the tool on {}
  # (k350). The streamed lift rebuilt the ToolCall from name/arguments only and
  # dropped the flag, so the streamed tool_calls disagreed with chat_f's for the
  # same reply. The streaming path runs no tool loop, so nothing acts on the
  # flag: it rides for parity, so aggregate_tool_calls returns the same calls,
  # as equal ToolCall objects, that chat_f's reply carries (its POD contract)
  # -- karr k351.
  for my $case (
    [ 'a non-object (string)' => '<tool_call>{"name":"go","arguments":"x=1"}</tool_call>' ],
    [ 'a JSON array'          => '<tool_call>{"name":"go","arguments":[1,2]}</tool_call>' ],
  ) {
    my ( $label, $text ) = @$case;
    my $parity = chat_f_turn( [], $text );
    my $ptc    = $parity->tool_calls->[0];
    ok( $ptc->arguments_undecodable, "$label: chat_f flags it (k350)" );
    for my $size ( 1, 4, length $text ) {
      my $r  = stream_turn( [], [ $text =~ /(.{1,$size})/sg ] );
      my $tc = $r->{calls}[0];
      ok( defined $tc, "$label, size $size: the call landed" ) or next;
      is( $tc->name, 'go', "$label, size $size: name as chat_f's" );
      ok( $tc->arguments_undecodable,
        "$label, size $size: streamed call carries arguments_undecodable" );
      is( $tc->arguments_error, $ptc->arguments_error,
        "$label, size $size: same reason as chat_f" );
      is_deeply( $tc->arguments, {}, "$label, size $size: arguments stay {}" );
    }
  }
};

subtest 'finish_reason: tool_calls over stop, a provider value kept' => sub {
  my $r = stream_turn( [], [ $REPLY ] );
  is( $r->{chunks}[-1]->finish_reason, 'tool_calls', 'stream: stop becomes tool_calls' );
  is( chat_f_turn( [], $REPLY )->finish_reason, 'tool_calls', 'chat_f: likewise' );

  my @events = ( sse( [ $REPLY ], truncated => 1 ),
    'data: ' . $json->encode({ choices => [ { index => 0, delta => {}, finish_reason => 'length' } ] }) . "\n\n" );
  my $engine = nous( _async_http => MockSSEHTTP->new(@events) );
  my ( undef, $chunks ) = $engine->chat_stream_realtime_f( messages => ['x'], tools => [$TOOL] )->get;
  is( $chunks->[-1]->finish_reason, 'length', 'stream: a length finish stays' );
  is( scalar @{ $engine->aggregate_tool_calls($chunks) }, 1, 'the call still lands' );

  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({ choices => [ { index => 0,
      message => { role => 'assistant', content => $REPLY }, finish_reason => 'length' } ] }) ] );
  my $resp = nous( _async_http => $mock )->chat_f( messages => ['x'], tools => [$TOOL] )->get;
  is( $resp->finish_reason, 'length', 'chat_f: a length finish stays' );

  $resp = chat_f_turn( [], $REPLY );
  is( $resp->raw->{choices}[0]{finish_reason}, 'stop', 'chat_f: raw keeps the wire value' );
  is( chat_f_turn( [], 'no call here' )->finish_reason, 'stop', 'chat_f: no call, stop stays' );
};

subtest 'a stream that ends without a final chunk' => sub {
  my $r = stream_turn( [], [ 'Hi <tool_' ], truncated => 1 );
  is( $r->{seen}, 'Hi <tool_', 'the held text is delivered on a closing chunk' );
  ok( $r->{chunks}[-1]->is_final, 'marked final' );

  $r = stream_turn( [], [ "Hi $CALL" ], truncated => 1 );
  is( $r->{seen}, 'Hi ', 'text streamed' );
  is_deeply( call_list( $r->{calls} ), [ [ get_weather => { city => 'Berlin' } ] ], 'the call is not lost' );
  is( $r->{chunks}[-1]->finish_reason, 'tool_calls', 'on a closing tool_calls chunk' );
};

subtest 'a mid-stream empty finish_reason is no finish' => sub {
  # Some servers send finish_reason "" on every delta; ending the lift there
  # would stream the rest of the markup as text (k253 review).
  my @events = map {
    'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => $_ },
      finish_reason => '' } ] }) . "\n\n"
  } ( 'Sure. <tool_', 'call>{"name":"get_weather","arguments":{"city":"Berlin"}}</tool_call>', ' ok' );
  push @events, 'data: ' . $json->encode({ choices => [ { index => 0, delta => {},
    finish_reason => 'stop' } ] }) . "\n\n", "data: [DONE]\n\n";
  my $engine = nous( _async_http => MockSSEHTTP->new(@events) );
  my $seen = '';
  my ( undef, $chunks ) = $engine->chat_stream_realtime_f( messages => ['weather?'], tools => [$TOOL],
    chunk_callback => sub { $seen .= $_[0]->content } )->get;
  is( $seen, 'Sure.  ok', 'the markup is withheld past the empty finish_reason' );
  is_deeply( call_list( $engine->aggregate_tool_calls($chunks) ), [ [ get_weather => { city => 'Berlin' } ] ],
    'the call lands' );
  is( $chunks->[-1]->finish_reason, 'tool_calls', 'on the real final chunk' );
};

subtest 'think tags: a call tag inside thinking is no call' => sub {
  my $text = '<think>maybe <tool_call>{"name":"nope","arguments":{}}</tool_call></think>'
    . "Sure.$CALL";
  my $parity = chat_f_turn( [], $text );
  for my $size ( 1, 3, 7 ) {
    my $r = stream_turn( [], [ $text =~ /(.{1,$size})/sg ] );
    is_deeply( call_list( $r->{calls} ), call_list( $parity->tool_calls ), "size $size: calls as chat_f" );
    is_deeply( call_list( $r->{calls} ), [ [ get_weather => { city => 'Berlin' } ] ], "size $size: the real call" );
    is( $r->{content}, 'Sure.', "size $size: content" );
    is( $r->{content}, $parity->content, "size $size: content as chat_f" );
    like( $r->{thinking}, qr/maybe <tool_call>/, "size $size: the thinking keeps its text" );
  }
};

# The chat template opened the thought in the prompt, so the reply's first
# think tag is a closing one; a call tag before it is thinking, as chat_f
# (ThinkTag's orphan rule) sees it (k302).
subtest 'orphan closing think tag: a call tag before it is no call' => sub {
  my $text = 'maybe <tool_call>{"name":"nope","arguments":{}}</tool_call></think>'
    . "Sure.$CALL";
  my $parity = chat_f_turn( [], $text );
  is_deeply( call_list( $parity->tool_calls ), [ [ get_weather => { city => 'Berlin' } ] ],
    'chat_f: only the call after the closing tag' );
  for my $size ( 1, 3, 7, length $text ) {
    my $r = stream_turn( [], [ $text =~ /(.{1,$size})/sg ] );
    is_deeply( call_list( $r->{calls} ), call_list( $parity->tool_calls ), "size $size: calls as chat_f" );
    is( $r->{content}, 'Sure.', "size $size: content" );
    is( $r->{content}, $parity->content, "size $size: content as chat_f" );
    like( $r->{thinking}, qr/maybe <tool_call>/, "size $size: the thinking keeps its text" );
    is( $r->{thinking}, $parity->thinking, "size $size: thinking as chat_f" );
  }
  my $late = stream_turn( [], [ "Sure.$CALL", ' done</think>' ] );
  is_deeply( call_list( $late->{calls} ), call_list( chat_f_turn( [], "Sure.$CALL done</think>" )->tool_calls ),
    'a call before a trailing orphan closing tag: as chat_f' );
};

subtest 'unchanged: no tools, tool_choice none, non-hermes, AKI native' => sub {
  my $r = stream_turn( [], [ $REPLY ], no_tools => 1 );
  is( $r->{seen}, $REPLY, 'hermes without tools: the tags stay in the text' );
  is_deeply( $r->{calls}, [], 'no call' );

  # The withhold is loud: collect that carp, pass anything else on.
  my @withheld;
  {
    local $SIG{__WARN__} = sub {
      return push @withheld, $_[0] if $_[0] =~ /tool_choice none on the hermes tool wire/;
      warn @_;
    };
    $r = stream_turn( [], [ $REPLY ], tool_choice => 'none' );
  }
  is( scalar @withheld, 1, 'tool_choice none: one carp' ) or diag @withheld;
  like( $withheld[0], qr/\ALangertha::Engine::NousResearch: .*the tools were withheld from the system prompt/,
    'the carp names the engine and says the tools were withheld' );
  is( $r->{seen}, $REPLY, 'tool_choice none withholds the tools, so no lift' );

  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o',
    _async_http => MockSSEHTTP->new( sse( [ $REPLY ] ) ) );
  my $seen = '';
  $openai->chat_stream_realtime_f( messages => ['x'], tools => [$TOOL],
    chunk_callback => sub { $seen .= $_[0]->content } )->get;
  is( $seen, $REPLY, 'a non-hermes engine streams the text as it came' );

  my $aki = Langertha::Engine::AKI->new( api_key => 'k' );
  ok( !eval { $aki->chat_stream_realtime_f( messages => ['x'], tools => [$TOOL] )->get; 1 },
    'AKI native has no streaming' );
  like( $@, qr/does not support streaming/, 'and says so' );
};

done_testing;
