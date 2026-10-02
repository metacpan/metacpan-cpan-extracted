use strict;
use warnings;
use utf8;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;

# k19: a routed stream must deliver the backend's tool calls. Since k18 a
# tool-call stream closes with the honest reason (Anthropic stop_reason
# tool_use, OpenAI finish_reason tool_calls), but Knarr::Stream carried text
# only, so the client got told "call a tool" without any call to make -- an
# agent loop stalls on it. The stream now carries the complete
# Langertha::ToolCall objects the engine chunks (or the Passthrough upstream)
# delivered, and each protocol emits them before its terminal frames:
# Anthropic as tool_use content blocks with one input_json_delta, OpenAI as one
# delta.tool_calls chunk, Ollama as message.tool_calls on the done line. The
# arguments are checked with a non-ASCII value, since they end up as a JSON
# string inside a UTF-8 encoded frame and must not be encoded twice.

use Langertha::Stream::Chunk;
use Langertha::ToolCall;
use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
# Arguments are a JSON string inside an already decoded frame: characters.
my $args_json = JSON::MaybeXS->new( canonical => 1 );

sub weather_call { Langertha::ToolCall->new( id => 'call_a', name => 'weather', arguments => { city => 'Köln' } ) }
sub time_call    { Langertha::ToolCall->new( name => 'time', arguments => { tz => 'UTC' } ) }

# Streams like a core engine whose parser attaches finished ToolCall objects:
# text, then one chunk per completed call, then the terminal chunk.
{
  package ToolEngine;
  use Moose;
  use Future;
  has chat_model => ( is => 'ro', default => 'tool-1' );
  has plain      => ( is => 'ro', default => 0 );   # chunks without tool calls
  sub supports { $_[1] eq 'streaming' ? 1 : 0 }
  sub chat_stream_realtime_f {
    my ( $self, %args ) = @_;
    my $cb = $args{chunk_callback};
    $cb->( Langertha::Stream::Chunk->new( content => 'Checking' ) );
    unless ( $self->plain ) {
      $cb->( Langertha::Stream::Chunk->new( content => '', tool_calls => [ main::weather_call() ] ) );
      $cb->( Langertha::Stream::Chunk->new( content => '', tool_calls => [ main::time_call() ] ) );
    }
    $cb->( Langertha::Stream::Chunk->new(
      content => '', is_final => 1, finish_reason => 'tool_calls' ) );
    return Future->done;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package ToolRouter;
  use Moose;
  has engine => ( is => 'ro', required => 1 );
  sub resolve { ( $_[0]->engine, 'tool-1' ) }
  sub list_models { [ { id => 'tool-1', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

{
  package RecTracer;
  use Moose;
  has ended => ( is => 'rw' );
  sub start_trace { {} }
  sub end_trace   { my ( $self, $t, %o ) = @_; $self->ended( \%o ) }
  __PACKAGE__->meta->make_immutable;
}

{
  package RecLog;
  use Moose;
  has ended => ( is => 'rw' );
  sub start_request { {} }
  sub end_request   { my ( $self, $h, %o ) = @_; $self->ended( \%o ) }
  __PACKAGE__->meta->make_immutable;
}

my $session = Langertha::Knarr::Session->new( id => 's' );
my $sreq = Langertha::Knarr::Request->new(
  protocol => 'openai', model => 'tool-1', stream => 1,
  messages => [ { role => 'user', content => 'hi' } ],
);

sub drain {
  my ($stream) = @_;
  my $text = '';
  while ( defined( my $c = $stream->next_chunk_f->get ) ) { $text .= $c }
  return $text;
}

sub call_names { [ map { $_->name } @{ $_[0] } ] }

subtest 'Stream collects tool calls' => sub {
  my $s = Langertha::Knarr::Stream->from_callback( sub {
    my ( $emit, $done, $fail, $finish, $tool_call ) = @_;
    $emit->('a');
    $tool_call->( weather_call() );
    $tool_call->();
    $tool_call->( time_call() );
    $done->();
  });
  is drain($s), 'a', 'text still flows';
  ok $s->has_tool_calls, 'has_tool_calls';
  is call_names( $s->tool_calls ), [qw( weather time )], 'calls appended in order';

  my $wrap = Langertha::Knarr::Stream->new( upstream => $s, source => sub { Future->done(undef) } );
  is call_names( $wrap->tool_calls ), [qw( weather time )], 'a wrapping stream answers with its upstream calls';

  my $none = Langertha::Knarr::Stream->from_list('x');
  is $none->tool_calls, [], 'no calls by default';
  ok !$none->has_tool_calls, 'has_tool_calls false';
};

subtest 'engine handlers collect the chunk tool calls' => sub {
  for my $case (
    [ Engine => sub { Langertha::Knarr::Handler::Engine->new( engine => $_[0] ) } ],
    [ Router => sub { Langertha::Knarr::Handler::Router->new( router => ToolRouter->new( engine => $_[0] ) ) } ],
  ) {
    my ( $name, $build ) = @$case;
    my $stream = $build->( ToolEngine->new )->handle_stream_f( $session, $sreq )->get;
    is drain($stream), 'Checking', "$name: text";
    is call_names( $stream->tool_calls ), [qw( weather time )], "$name: both calls";
    is $stream->tool_calls->[0]->arguments, { city => 'Köln' }, "$name: arguments intact";
    is $stream->finish_reason, 'tool_calls', "$name: reason";

    my $plain = $build->( ToolEngine->new( plain => 1 ) )->handle_stream_f( $session, $sreq )->get;
    drain($plain);
    is $plain->tool_calls, [], "$name: chunks without tool calls give none (core parser attaches none)";
  }
};

subtest 'decorators pass the calls through and record them' => sub {
  my $tracer = RecTracer->new;
  my $h = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Engine->new( engine => ToolEngine->new ),
    tracing => $tracer,
  );
  my $stream = $h->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is call_names( $stream->tool_calls ), [qw( weather time )], 'Tracing stream reports the inner calls';
  is call_names( $tracer->ended->{tool_calls} ), [qw( weather time )], 'trace records the calls';

  my $log = RecLog->new;
  my $rl = Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => Langertha::Knarr::Handler::Engine->new( engine => ToolEngine->new ),
    request_log => $log,
  );
  $stream = $rl->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is call_names( $stream->tool_calls ), [qw( weather time )], 'RequestLog stream reports the inner calls';
  is call_names( $log->ended->{tool_calls} ), [qw( weather time )], 'request log records the calls';

  my $plain_tracer = RecTracer->new;
  $stream = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Engine->new( engine => ToolEngine->new( plain => 1 ) ),
    tracing => $plain_tracer,
  )->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  ok !exists $plain_tracer->ended->{tool_calls}, 'no tool_calls key without calls';
};

subtest 'non-streaming fallback takes the calls from the Response' => sub {
  my $h = Langertha::Knarr::Handler::Engine->new( engine => ToolEngine->new );
  no warnings 'redefine';
  local *Langertha::Knarr::Handler::Engine::_supports_streaming = sub { 0 };
  local *Langertha::Knarr::Handler::Engine::handle_chat_f = sub {
    Future->done( Langertha::Knarr::Response->new(
      content => '', finish_reason => 'tool_calls', tool_calls => [ weather_call() ] ) );
  };
  my $stream = $h->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is call_names( $stream->tool_calls ), ['weather'], 'calls from the Response';
};

# --- Wire readers: rebuild the calls the way a client does ---

sub sse_events {
  my ($body) = @_;
  my @events;
  for my $block ( grep { length } split /\n\n/, $body ) {
    my ($event) = $block =~ /^event: (.+)$/m;
    my ($data)  = $block =~ /^data: (.+)$/m;
    push @events, [ $event, $data eq '[DONE]' ? $data : $json->decode($data) ];
  }
  return @events;
}

# Every Anthropic frame is well formed: the SSE event name equals the data
# type, blocks are started before they get deltas and stopped exactly once.
sub anthropic_calls {
  my ($body) = @_;
  my ( %open, %stopped, %calls, @order );
  my $ok = 1;
  for my $ev ( sse_events($body) ) {
    my ( $name, $data ) = @$ev;
    $ok = 0 unless ref $data eq 'HASH' && defined $name && $name eq ( $data->{type} // '' );
    my $type = $data->{type} // '';
    my $idx  = $data->{index};
    if ( $type eq 'content_block_start' ) {
      $ok = 0 if $open{$idx}++;
      if ( $data->{content_block}{type} eq 'tool_use' ) {
        $ok = 0 unless ref $data->{content_block}{input} eq 'HASH';
        $calls{$idx} = { id => $data->{content_block}{id}, name => $data->{content_block}{name}, json => '' };
        push @order, $idx;
      }
    }
    elsif ( $type eq 'content_block_delta' ) {
      $ok = 0 unless $open{$idx} && !$stopped{$idx};
      $calls{$idx}{json} .= $data->{delta}{partial_json} if $data->{delta}{type} eq 'input_json_delta';
    }
    elsif ( $type eq 'content_block_stop' ) {
      $ok = 0 unless $open{$idx} && !$stopped{$idx}++;
    }
  }
  $ok = 0 if grep { !$stopped{$_} } keys %open;
  my @calls = map {
    { id => $calls{$_}{id}, name => $calls{$_}{name}, arguments => $args_json->decode( $calls{$_}{json} ) }
  } @order;
  return ( $ok, \@calls );
}

sub openai_calls {
  my ($body) = @_;
  my %calls;
  for my $ev ( sse_events($body) ) {
    my $data = $ev->[1];
    next unless ref $data eq 'HASH';
    for my $frag ( @{ $data->{choices}[0]{delta}{tool_calls} // [] } ) {
      my $c = $calls{ $frag->{index} } //= { args => '' };
      $c->{id}   = $frag->{id} if defined $frag->{id};
      $c->{name} = $frag->{function}{name} if defined $frag->{function}{name};
      $c->{args} .= $frag->{function}{arguments} // '';
    }
  }
  return [ map {
    { id => $calls{$_}{id}, name => $calls{$_}{name}, arguments => $args_json->decode( $calls{$_}{args} ) }
  } sort { $a <=> $b } keys %calls ];
}

my $req = Langertha::Knarr::Request->new( protocol => 'openai', model => 'tool-1' );
my $oa = Langertha::Knarr::Protocol::OpenAI->new;
my $an = Langertha::Knarr::Protocol::Anthropic->new;
my $ol = Langertha::Knarr::Protocol::Ollama->new;

subtest 'Anthropic frames each call as a tool_use block' => sub {
  my $out = $an->format_stream_close( $req, 'tool_calls', [ weather_call(), time_call() ] );
  my ( $ok, $calls ) = anthropic_calls( $an->format_stream_open($req) . $out );
  ok $ok, 'event names match data types, blocks start/delta/stop in order';
  is $calls, [
    { id => 'call_a',       name => 'weather', arguments => { city => 'Köln' } },
    { id => 'toolu_knarr_2', name => 'time',    arguments => { tz => 'UTC' } },
  ], 'calls whole, a missing id gets a unique fallback';
  my @names = map { $_->[0] } sse_events($out);
  is \@names, [qw(
    content_block_stop
    content_block_start content_block_delta content_block_stop
    content_block_start content_block_delta content_block_stop
    message_delta message_stop
  )], 'text block closes, tool blocks follow, then the terminal frames';
  like $out, qr/"stop_reason":"tool_use"/, 'stop_reason tool_use';
  like $an->format_stream_close( $req, undef, [ weather_call() ] ), qr/"stop_reason":"tool_use"/,
    'calls without a reason still stop with tool_use';
  unlike $an->format_stream_close( $req, 'stop', [] ), qr/tool_use/, 'no calls, no tool_use block';
};

subtest 'OpenAI sends all calls in one delta.tool_calls chunk' => sub {
  my $out = $oa->format_stream_close( $req, 'stop', [ weather_call(), time_call() ] );
  my @chunks = map { $_->[1] } sse_events($out);
  is scalar @chunks, 2, 'one tool_calls chunk, one terminal chunk';
  is $chunks[0]{choices}[0]{finish_reason}, undef, 'tool_calls chunk sets no finish_reason';
  is [ map { $_->{index} } @{ $chunks[0]{choices}[0]{delta}{tool_calls} } ], [ 0, 1 ], 'indexed';
  is [ map { $_->{type} } @{ $chunks[0]{choices}[0]{delta}{tool_calls} } ], [qw( function function )], 'type function';
  is openai_calls($out), [
    { id => 'call_a',       name => 'weather', arguments => { city => 'Köln' } },
    { id => 'call_knarr_2', name => 'time',    arguments => { tz => 'UTC' } },
  ], 'calls whole, a missing id gets a unique fallback';
  is $chunks[1]{choices}[0]{delta}, {}, 'terminal chunk has an empty delta';
  is $chunks[1]{choices}[0]{finish_reason}, 'tool_calls', 'calls force finish_reason tool_calls';
  is scalar( () = sse_events( $oa->format_stream_close( $req, 'stop', [] ) ) ), 1, 'no calls, terminal chunk only';
};

subtest 'Ollama puts the calls on the done line' => sub {
  my $done = $json->decode( $ol->format_stream_done( $req, 'tool_calls', [ weather_call(), time_call() ] ) );
  ok $done->{done}, 'done line';
  is $done->{message}{tool_calls}, [
    { id => 'call_a', function => { name => 'weather', arguments => { city => 'Köln' } } },
    { function => { name => 'time', arguments => { tz => 'UTC' } } },
  ], 'message.tool_calls whole';
  is $done->{done_reason}, 'stop', 'done_reason stays in Ollama vocabulary';
  ok !exists $json->decode( $ol->format_stream_done( $req, 'stop', [] ) )->{message}{tool_calls},
    'no calls, no tool_calls key';
};

# --- Passthrough assembles fragmented upstream tool calls ---

my $loop = IO::Async::Loop->new;

my %UPSTREAM = (
  '/v1/chat/completions' => [ 'text/event-stream', join '', map { "data: $_\n\n" }
    '{"choices":[{"index":0,"delta":{"role":"assistant","content":"Hi"}}]}',
    '{"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_x","type":"function","function":{"name":"weather","arguments":""}}]}}]}',
    '{"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"city\":"}}]}}]}',
    '{"choices":[{"index":0,"delta":{"tool_calls":[{"index":1,"id":"call_y","type":"function","function":{"name":"time","arguments":"{}"}}]}}]}',
    '{"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"\"Köln\"}"}}]}}]}',
    '{"choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}]}',
    '[DONE]' ],
  '/v1/messages' => [ 'text/event-stream', join '', map { "event: $_->[0]\ndata: $_->[1]\n\n" }
    [ message_start       => '{"type":"message_start","message":{"id":"m","type":"message","role":"assistant","content":[]}}' ],
    [ content_block_start => '{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}' ],
    [ content_block_delta => '{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hi"}}' ],
    [ content_block_stop  => '{"type":"content_block_stop","index":0}' ],
    [ content_block_start => '{"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_x","name":"weather","input":{}}}' ],
    [ content_block_delta => '{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":""}}' ],
    [ content_block_delta => '{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"city\":"}}' ],
    [ content_block_delta => '{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"\"Köln\"}"}}' ],
    [ content_block_stop  => '{"type":"content_block_stop","index":1}' ],
    [ content_block_start => '{"type":"content_block_start","index":2,"content_block":{"type":"tool_use","id":"toolu_y","name":"time","input":{}}}' ],
    [ content_block_stop  => '{"type":"content_block_stop","index":2}' ],
    [ message_delta       => '{"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":5}}' ],
    [ message_stop        => '{"type":"message_stop"}' ] ],
  '/api/chat' => [ 'application/x-ndjson', join '', map { "$_\n" }
    '{"message":{"role":"assistant","content":"Hi"},"done":false}',
    '{"message":{"role":"assistant","content":"","tool_calls":[{"function":{"name":"weather","arguments":{"city":"Köln"}}}]},"done":false}',
    '{"message":{"role":"assistant","content":""},"done":true,"done_reason":"stop"}' ],
);

my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $srv, $r ) = @_;
    my $spec = $UPSTREAM{ $r->path } or return $r->respond( HTTP::Response->new(404) );
    my $resp = HTTP::Response->new(200);
    $resp->header( 'Content-Type' => $spec->[0] );
    my $bytes = $spec->[1];
    utf8::encode($bytes);
    $resp->content($bytes);
    $resp->content_length( length $bytes );
    $r->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $uport = $upstream->read_handle->sockport;

subtest 'Passthrough assembles fragmented upstream calls' => sub {
  my $pt = Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { map { $_ => "http://127.0.0.1:$uport" } qw( openai anthropic ollama ) },
    loop      => $loop,
  );
  my %want = (
    openai => [
      [ call_x => weather => { city => 'Köln' } ],
      [ call_y => time    => {} ],
    ],
    anthropic => [
      [ toolu_x => weather => { city => 'Köln' } ],
      [ toolu_y => time    => {} ],
    ],
    ollama => [
      [ '' => weather => { city => 'Köln' } ],
    ],
  );
  for my $proto (qw( openai anthropic ollama )) {
    my $r = Langertha::Knarr::Request->new(
      protocol => $proto, model => 'm', stream => 1,
      messages => [ { role => 'user', content => 'hi' } ],
      raw => { model => 'm', messages => [ { role => 'user', content => 'hi' } ] },
    );
    my $stream = $pt->handle_stream_f( $session, $r )->get;
    my $text = '';
    while ( defined( my $c = $loop->await( $stream->next_chunk_f )->get ) ) { $text .= $c }
    is $text, 'Hi', "$proto: text";
    is [ map { [ $_->id, $_->name, $_->arguments ] } @{ $stream->tool_calls } ], $want{$proto},
      "$proto: calls assembled whole";
  }
};

# A real core engine against the fragmented upstream. Core assembles streamed
# delta.tool_calls into ToolCall objects on the finish chunk since k221; a core
# whose parser does not (0.503 on CPAN) attaches none, and Knarr then streams
# no calls rather than failing -- probed, not assumed from $VERSION (both say
# 0.503).
subtest 'real core engine: Handler::Engine streams what core assembled' => sub {
  require Langertha::Engine::OpenAI;
  my $engine = Langertha::Engine::OpenAI->new(
    url => "http://127.0.0.1:$uport/v1", api_key => 'test', model => 'm',
  );
  my $probe = $engine->parse_stream_chunk( { choices => [ {
    index => 0, finish_reason => 'tool_calls',
    delta => { tool_calls => [ { index => 0, id => 'p', type => 'function',
      function => { name => 'probe', arguments => '{}' } } ] },
  } ] }, undef, {} );
  my $core_assembles = $probe && $probe->can('has_tool_calls') && $probe->has_tool_calls;
  note $core_assembles ? 'core assembles streamed tool calls' : 'core attaches no streamed tool calls';

  my $r = Langertha::Knarr::Request->new(
    protocol => 'openai', model => 'm', stream => 1,
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $stream = Langertha::Knarr::Handler::Engine->new( engine => $engine )
    ->handle_stream_f( $session, $r )->get;
  my $text = '';
  while ( defined( my $c = $loop->await( $stream->next_chunk_f )->get ) ) { $text .= $c }
  is $text, 'Hi', 'text';
  if ($core_assembles) {
    is [ map { [ $_->id, $_->name, $_->arguments ] } @{ $stream->tool_calls } ],
      [ [ call_x => weather => { city => 'Köln' } ], [ call_y => time => {} ] ],
      'calls as core assembled them';
    my $out = $oa->format_stream_close( $r, $stream->finish_reason, $stream->tool_calls );
    is [ map { $_->{name} } @{ openai_calls($out) } ], [qw( weather time )], 'and framed for the client';
  }
  else {
    is $stream->tool_calls, [], 'no calls, no failure';
  }
};

# --- End to end: a real Knarr server in front of the tool engine ---

my $backend = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Engine->new( engine => ToolEngine->new ),
  loop    => $loop,
  port    => 0,
);
$backend->start;
my $bport = $backend->_server->read_handle->sockport;

# A second Knarr that forwards to the first through Handler::Passthrough: the
# calls must survive the protocol-native round trip.
my $front = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { map { $_ => "http://127.0.0.1:$bport" } qw( openai anthropic ollama ) },
    loop      => $loop,
  ),
  loop => $loop,
  port => 0,
);
$front->start;
my $fport = $front->_server->read_handle->sockport;

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post_stream {
  my ( $port, $path ) = @_;
  my $r = HTTP::Request->new( POST => "http://127.0.0.1:$port$path" );
  $r->header( 'Content-Type' => 'application/json' );
  $r->content( $json->encode({
    model => 'tool-1', max_tokens => 16, stream => JSON::MaybeXS::true(),
    messages => [ { role => 'user', content => 'hi' } ],
  }) );
  return $http->do_request( request => $r )->get->content;
}

sub check_wire {
  my ( $label, $get, $anthropic_second_id, $openai_second_id ) = @_;

  my $openai = $get->('/v1/chat/completions');
  is openai_calls($openai), [
    { id => 'call_a',          name => 'weather', arguments => { city => 'Köln' } },
    { id => $openai_second_id, name => 'time',    arguments => { tz => 'UTC' } },
  ], "$label openai: calls";
  my @data = map { $_->[1] } sse_events($openai);
  is $data[-1], '[DONE]', "$label openai: ends with [DONE]";
  is $data[-2]{choices}[0]{finish_reason}, 'tool_calls', "$label openai: terminal finish_reason tool_calls";
  ok !$data[-2]{choices}[0]{delta}{tool_calls}, "$label openai: calls precede the terminal chunk";

  my ( $ok, $calls ) = anthropic_calls( $get->('/v1/messages') );
  ok $ok, "$label anthropic: frames well formed";
  is $calls, [
    { id => 'call_a',             name => 'weather', arguments => { city => 'Köln' } },
    { id => $anthropic_second_id, name => 'time',    arguments => { tz => 'UTC' } },
  ], "$label anthropic: calls";
  like $get->('/v1/messages'), qr/"stop_reason":"tool_use".*event: message_stop/s, "$label anthropic: tool_use stop";

  my @ndjson = map { $json->decode($_) } grep { length } split /\n/, $get->('/api/chat');
  ok $ndjson[-1]{done}, "$label ollama: last line is done";
  is [ map { $_->{function}{name} } @{ $ndjson[-1]{message}{tool_calls} } ], [qw( weather time )],
    "$label ollama: calls on the done line";
  is $ndjson[-1]{message}{tool_calls}[0]{function}{arguments}, { city => 'Köln' }, "$label ollama: arguments";
}

subtest 'Knarr server streams the tool calls' => sub {
  check_wire( 'direct', sub { post_stream( $bport, $_[0] ) }, 'toolu_knarr_2', 'call_knarr_2' );
};

subtest 'Handler::Passthrough carries the upstream tool calls' => sub {
  # The front re-frames the ids the backend assigned.
  check_wire( 'passthrough', sub { post_stream( $fport, $_[0] ) }, 'toolu_knarr_2', 'call_knarr_2' );
};

subtest 'PSGI buffered stream carries the tool calls' => sub {
  plan skip_all => 'Plack::Test required'
    unless eval { require Plack::Test; require HTTP::Request::Common; 1 };
  my $app = Langertha::Knarr::PSGI->new( knarr => $backend )->to_app;
  my $test = Plack::Test->create($app);
  check_wire( 'psgi', sub {
    my $r = HTTP::Request->new( POST => $_[0] );
    $r->header( 'Content-Type' => 'application/json' );
    $r->content( $json->encode({
      model => 'tool-1', stream => JSON::MaybeXS::true(),
      messages => [ { role => 'user', content => 'hi' } ],
    }) );
    $test->request($r)->content;
  }, 'toolu_knarr_2', 'call_knarr_2' );
};

done_testing;
