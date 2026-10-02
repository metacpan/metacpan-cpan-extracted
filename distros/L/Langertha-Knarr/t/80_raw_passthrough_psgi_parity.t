use strict;
use warnings;
use Test2::V0;

# Regression (k26): under Plack, Langertha::Knarr::PSGI sent every chat
# request through the handler chain, while the native server's
# _action_chat pipes a passthrough model's request 1:1 to the upstream and
# its answer 1:1 back. The same Knarr config therefore behaved differently
# depending on the transport: tool_use, usage, cache_control and every
# other upstream field survived natively but were re-framed (or lost) by
# the handler under PSGI. One table drives both transports so they cannot
# drift apart again: same status, same content type, the upstream's bytes
# unchanged, the client's body and headers forwarded unchanged, the
# handler chain never reached, and the same trace. PSGI buffers a stream;
# the bytes are still the upstream's.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use HTTP::Response;
use IO::Async::Loop;
use IO::Socket::INET;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;

{
  package ParityRouter;   # only the passthrough decision is needed here
  sub new { bless {}, shift }
  sub is_passthrough_model { my ($self, $model) = @_; ( $model // '' ) =~ /\Apt-/ ? 1 : 0 }
}
{
  package ParityTracer;
  sub new { bless { events => [] }, shift }
  sub start_trace { my ($self, %o) = @_; push @{ $self->{events} }, [ start => \%o ]; return { id => scalar @{ $self->{events} } } }
  sub end_trace { my ($self, $info, %o) = @_; push @{ $self->{events} }, [ end => \%o ] }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Upstream: canned bytes per protocol (non-ASCII, fields no handler
#     would reproduce), records what reached it.
my %canned = (
  '/v1/chat/completions' => [ 'application/json',
    qq({"choices":[{"finish_reason":"tool_calls","index":0,"message":{"content":"Gr\xc3\xbc\xc3\x9fe \xe2\x82\xac","role":"assistant","tool_calls":[{"function":{"arguments":"{\\"q\\":1}","name":"lookup"},"id":"call_1","type":"function"}]}}],"id":"up-1","usage":{"prompt_tokens":3}}) ],
  '/v1/messages' => [ 'application/json',
    qq({"content":[{"text":"hi","type":"text"}],"id":"msg_up","stop_reason":"end_turn","usage":{"cache_read_input_tokens":42,"input_tokens":1}}) ],
  '/api/chat' => [ 'application/json',
    qq({"done":true,"message":{"content":"\xc3\xb6","role":"assistant"},"model":"pt-o"}) ],
);
my %canned_stream = (
  '/v1/chat/completions' => [ 'text/event-stream',
    [ qq(data: {"choices":[{"delta":{"content":"\xc3\xa4"}}]}\n\n), qq(data: {"choices":[{"delta":{},"finish_reason":"stop"}]}\n\n), "data: [DONE]\n\n" ] ],
  '/v1/messages' => [ 'text/event-stream',
    [ qq(event: content_block_delta\ndata: {"delta":{"text":"x","type":"text_delta"},"type":"content_block_delta"}\n\n), qq(event: message_stop\ndata: {"type":"message_stop"}\n\n) ] ],
  '/api/chat' => [ 'application/x-ndjson',
    [ qq({"done":false,"message":{"content":"a"}}\n), qq({"done":true,"done_reason":"stop"}\n) ] ],
);

my @upstream_seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my %h = map { lc( $_->[0] ) => $_->[1] } $req->headers;
    push @upstream_seen, { path => $req->path, body => $req->body, headers => \%h };
    my $sent = $req->body // '';
    # Ollama streams unless told not to.
    my $streaming = $sent =~ /"stream":true/
      || ( $req->path eq '/api/chat' && $sent !~ /"stream":false/ );
    if ( $streaming ) {
      my ($ctype, $chunks) = @{ $canned_stream{ $req->path } };
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => $ctype );
      $req->respond_chunk_header($head);
      $req->write_chunk($_) for @$chunks;
      $req->write_chunk_eof;
      return;
    }
    my ($ctype, $body) = @{ $canned{ $req->path } };
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => $ctype, 'Content-Length' => length $body );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $dead_port = do {
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 ) or die $!;
  my $p = $s->sockport; close $s; $p;
};

my $handler_calls = 0;
my $handler = Langertha::Knarr::Handler::Code->new(
  code        => sub { $handler_calls++; 'from-handler' },
  stream_code => sub { $handler_calls++; my @p = ('h'); sub { @p ? shift @p : undef } },
);

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %setup;
for my $name ( 'live', 'dead' ) {
  my $base = $name eq 'live' ? $up : "http://127.0.0.1:$dead_port";
  my $tracer = ParityTracer->new;
  my $knarr = Langertha::Knarr->new(
    handler         => $handler,
    loop            => $loop,
    listen          => [ '127.0.0.1:0' ],
    router          => ParityRouter->new,
    raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
      upstreams => { openai => $base, anthropic => $base, ollama => $base },
      loop      => $loop,
    ),
    tracing         => $tracer,
  );
  $knarr->start;
  $setup{$name} = {
    tracer => $tracer,
    port   => $knarr->_server->read_handle->sockport,
    psgi   => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

my $msgs = [ { role => 'user', content => "hi \x{263a}" } ];
my $T = JSON::MaybeXS::true();
my $F = JSON::MaybeXS::false();
my @forwarded_headers = ( 'x-api-key' => 'sk-client', 'anthropic-version' => '2023-06-01',
  'X-Custom-Trace' => 'abc' );

# path, body, setup, expectation
my @table = (
  [ 'openai sync',      '/v1/chat/completions', { model => 'pt-gpt', messages => $msgs }, 'live', 'passthrough' ],
  [ 'openai stream',    '/v1/chat/completions', { model => 'pt-gpt', messages => $msgs, stream => $T }, 'live', 'passthrough' ],
  [ 'anthropic sync',   '/v1/messages', { model => 'pt-claude', max_tokens => 5, messages => $msgs }, 'live', 'passthrough' ],
  [ 'anthropic stream', '/v1/messages', { model => 'pt-claude', max_tokens => 5, messages => $msgs, stream => $T }, 'live', 'passthrough' ],
  [ 'ollama sync',      '/api/chat', { model => 'pt-o', messages => $msgs, stream => $F }, 'live', 'passthrough' ],
  [ 'ollama stream',    '/api/chat', { model => 'pt-o', messages => $msgs }, 'live', 'passthrough' ],
  [ 'upstream down',    '/v1/chat/completions', { model => 'pt-gpt', messages => $msgs }, 'dead', 'bad_gateway' ],
  [ 'routed model',     '/v1/chat/completions', { model => 'routed', messages => $msgs }, 'live', 'handler' ],
);

for my $row (@table) {
  my ($label, $path, $body, $where, $expect) = @$row;
  my $s = $setup{$where};
  my $content = $json->encode($body);
  my @h = ( 'Content-Type' => 'application/json', @forwarded_headers );

  my %got;
  for my $transport ( 'native', 'psgi' ) {
    @upstream_seen = ();
    @{ $s->{tracer}{events} } = ();
    $handler_calls = 0;
    my $resp = $transport eq 'native'
      ? $http->do_request( request =>
          HTTP::Request->new( POST => "http://127.0.0.1:$s->{port}$path", \@h, $content ) )->get
      : $s->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $content ) );
    $got{$transport} = {
      resp     => $resp,
      upstream => [ @upstream_seen ],
      events   => [ @{ $s->{tracer}{events} } ],
      handler  => $handler_calls,
    };
  }
  my ($n, $p) = @got{qw( native psgi )};

  is( $p->{resp}->code, $n->{resp}->code, "$label: PSGI status matches native" );
  is( $p->{handler}, $n->{handler}, "$label: handler reached equally often" );

  if ( $expect eq 'handler' ) {
    is( $n->{handler}, 1, "$label: a configured model goes through the handler" );
    is( $n->{upstream}, [], "$label: and never reaches the passthrough upstream" );
    is( $p->{upstream}, [], "$label: (PSGI too)" );
    next;
  }

  is( $n->{handler}, 0, "$label: handler chain skipped" );
  is( $p->{events}, $n->{events}, "$label: same trace on both transports" );
  is( [ map { $_->[0] } @{ $n->{events} } ], [qw( start end )], "$label: trace started and ended" );
  is( $n->{events}[0][1]{engine}, 'passthrough', "$label: traced as passthrough" );

  if ( $expect eq 'bad_gateway' ) {
    is( $n->{resp}->code, 502, "$label: 502 from native" );
    is( $p->{resp}->content, $n->{resp}->content, "$label: same 502 body" );
    like( $p->{resp}->content, qr/passthrough failed/, "$label: 502 body names the failure" );
    next;
  }

  my $stream = $body->{stream} // ( $path eq '/api/chat' ? 1 : 0 );
  $stream = 0 if ref $stream && !$stream;
  my ($ctype, $expected) = $stream
    ? ( $canned_stream{$path}[0], join '', @{ $canned_stream{$path}[1] } )
    : @{ $canned{$path} };

  is( $n->{resp}->code, 200, "$label: 200" );
  is( scalar $p->{resp}->header('Content-Type'), $ctype, "$label: PSGI keeps the upstream content type" );
  is( scalar $n->{resp}->header('Content-Type'), $ctype, "$label: native keeps the upstream content type" );
  is( $n->{resp}->content, $expected, "$label: native returns the upstream bytes 1:1" );
  is( $p->{resp}->content, $expected, "$label: PSGI returns the upstream bytes 1:1" );

  is( scalar @{ $n->{upstream} }, 1, "$label: native hits the upstream once" );
  is( scalar @{ $p->{upstream} }, 1, "$label: PSGI hits the upstream once" );
  my ($nu, $pu) = ( $n->{upstream}[0], $p->{upstream}[0] );
  is( $pu->{path}, $nu->{path}, "$label: same upstream path" );
  is( $nu->{body}, $content, "$label: native forwards the client body 1:1" );
  is( $pu->{body}, $content, "$label: PSGI forwards the client body 1:1" );
  for my $hname ( 'x-api-key', 'anthropic-version', 'x-custom-trace', 'content-type' ) {
    is( $pu->{headers}{$hname}, $nu->{headers}{$hname}, "$label: header $hname forwarded alike" );
    ok( defined $nu->{headers}{$hname}, "$label: header $hname reaches the upstream" );
  }
}

done_testing;
