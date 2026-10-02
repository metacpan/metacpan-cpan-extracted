use strict;
use warnings;
use Test2::V0;

# Regression (k35): Knarr's own HTTP client had no timeout. An upstream that
# accepts the connection and never answers -- or stops feeding a stream --
# held the client's request open forever, on the native server and under
# PSGI alike. Every upstream call now carries a timeout: the total time for
# a plain request, the time without data (stall) for a stream, where a long
# steady stream is legitimate. An expired raw passthrough answers 504 in the
# client protocol's own error shape; a stream whose headers are already out
# ends with the protocol's error frame. The A2A / ACP clients time out too,
# and routed engines get the proxy's upstream_timeout as user_agent_timeout.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use JSON::MaybeXS;
use Time::HiRes qw( time );

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Handler::A2AClient;
use Langertha::Knarr::Handler::ACPClient;
use Langertha::Knarr::PSGI;

{
  package TimeoutRouter;   # every model is a passthrough model here
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Upstream. X-Mode picks the misbehavior; the requests it never answers
#     are kept so their connections stay open.
my @held;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my $mode = ( map { $_->[1] } grep { lc $_->[0] eq 'x-mode' } $req->headers )[0] // 'hang';
    push @held, $req;
    return if $mode eq 'hang';
    my $ctype = $req->path eq '/api/chat' ? 'application/x-ndjson' : 'text/event-stream';
    my $head = HTTP::Response->new(200);
    $head->protocol('HTTP/1.1');
    $head->header( 'Content-Type' => $ctype );
    $req->respond_chunk_header($head);
    my %first = (
      '/v1/chat/completions' => qq(data: {"choices":[{"delta":{"content":"a"}}]}\n\n),
      '/v1/messages'         => qq(event: content_block_delta\ndata: {"delta":{"text":"a","type":"text_delta"},"type":"content_block_delta"}\n\n),
      '/api/chat'            => qq({"done":false,"message":{"content":"a"}}\n),
    );
    if ( $mode eq 'stall' ) {       # one whole frame, then silence
      $req->write_chunk( $first{ $req->path } );
    }
    elsif ( $mode eq 'partial' ) {  # half a frame, then silence
      $req->write_chunk(qq(data: {"choi));
    }
    elsif ( $mode eq 'steady' ) {   # a frame every 0.2s for 1.2s, then done
      my $n = 0;
      my $tick; $tick = sub {
        if ( ++$n > 6 ) { $req->write_chunk("data: [DONE]\n\n"); $req->write_chunk_eof; undef $tick; return }
        $req->write_chunk( $first{ $req->path } );
        $loop->delay_future( after => 0.2 )->on_done($tick)->retain;
      };
      $tick->();
    }
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $passthrough = Langertha::Knarr::Handler::Passthrough->new(
  upstreams     => { openai => $up, anthropic => $up, ollama => $up },
  loop          => $loop,
  timeout       => 0.5,
  stall_timeout => 0.5,
);
my $knarr = Langertha::Knarr->new(
  handler         => Langertha::Knarr::Handler::Code->new( code => sub { 'never' } ),
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
  router          => TimeoutRouter->new,
  raw_passthrough => $passthrough,
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my $client = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($client);

my $msgs = [ { role => 'user', content => 'hi' } ];
my %path = ( openai => '/v1/chat/completions', anthropic => '/v1/messages', ollama => '/api/chat' );

sub send_request {
  my ($transport, $proto, $mode, $stream) = @_;
  my $body = { model => 'pt-model', messages => $msgs,
    stream => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false() };
  $body->{max_tokens} = 5 if $proto eq 'anthropic';
  my @h = ( 'Content-Type' => 'application/json', 'X-Mode' => $mode );
  my $start = time;
  my $resp = $transport eq 'native'
    ? $client->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$port$path{$proto}", \@h, $json->encode($body) ), timeout => 10 )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path{$proto}", \@h, $json->encode($body) ) );
  return ( $resp, time - $start );
}

# The client protocol's error shape, carrying the timeout.
my %error_shape = (
  openai    => sub { hash { field error => hash { field message => match qr/passthrough failed: .*timed out after 0.5s/; end } ; end } },
  anthropic => sub { hash { field type => 'error';
    field error => hash { field type => 'timeout_error'; field message => match qr/timed out after 0.5s/; end }; end } },
  ollama    => sub { hash { field error => match qr/timed out after 0.5s/; end } },
);

# --- An upstream that never answers: 504, not a hang, on both transports.
for my $transport (qw( native psgi )) {
  for my $proto (qw( openai anthropic ollama )) {
    for my $stream ( 0, 1 ) {
      my $label = "$transport $proto " . ( $stream ? 'stream' : 'sync' ) . ', no answer';
      my ($resp, $took) = send_request( $transport, $proto, 'hang', $stream );
      is( $resp->code, 504, "$label: 504" );
      is( $json->decode( $resp->content ), $error_shape{$proto}->(), "$label: protocol's error shape" );
      ok( $took < 3, "$label: answered after the timeout, not never (${took}s)" );
    }
  }
}

# --- A stream that stops after its headers. Natively the headers and the
#     first frame are out: the stream ends with the protocol's error frame.
#     PSGI buffers the stream, so nothing is out yet: 504.
{
  my %frame = (
    openai    => qr/\Adata: \{"choices".*?\n\ndata: \{"error":\{"message":"[^"]*timed out after 0.5s without data"\}\}\n\n\z/s,
    anthropic => qr/\Aevent: content_block_delta\n.*?\n\nevent: error\ndata: \{"error":\{"message":"[^"]*timed out after 0.5s without data","type":"timeout_error"\},"type":"error"\}\n\n\z/s,
    ollama    => qr/\A\{"done":false[^\n]*\n\{"error":"[^"]*timed out after 0.5s without data"\}\n\z/s,
  );
  for my $proto (qw( openai anthropic ollama )) {
    my ($resp, $took) = send_request( 'native', $proto, 'stall', 1 );
    is( $resp->code, 200, "native $proto stall: the upstream's status went out" );
    like( $resp->content, $frame{$proto}, "native $proto stall: first frame, then the error frame" );
    ok( $took < 3, "native $proto stall: closed after the stall timeout (${took}s)" );

    my ($presp) = send_request( 'psgi', $proto, 'stall', 1 );
    is( $presp->code, 504, "psgi $proto stall: 504" );
    is( $json->decode( $presp->content ), $error_shape{$proto}->(), "psgi $proto stall: protocol's error shape" );
  }

  # A frame cut off by the stall is ended first, so the error frame is read
  # as its own event and not glued onto the broken one.
  my ($resp) = send_request( 'native', 'openai', 'partial', 1 );
  like( $resp->content, qr/\Adata: \{"choi\n\ndata: \{"error":/, 'native partial frame: ended before the error frame' );
}

# --- A long steady stream is not cut: the stall timeout counts silence,
#     not the stream's total length (1.2s here against a 0.5s timeout).
for my $transport (qw( native psgi )) {
  my ($resp, $took) = send_request( $transport, 'openai', 'steady', 1 );
  is( $resp->code, 200, "$transport steady stream: 200" );
  my @frames = $resp->content =~ /"content":"a"/g;
  is( scalar @frames, 6, "$transport steady stream: every frame arrived" );
  like( $resp->content, qr/data: \[DONE\]\n\n\z/, "$transport steady stream: ended by the upstream, no error frame" );
  ok( $took > 1, "$transport steady stream: outlived the 0.5s stall timeout (${took}s)" );
}

# --- Handler::Passthrough (the handler chain, not the raw path) times out too.
{
  my $session = Langertha::Knarr::Session->new( id => 's' );
  my $req = Langertha::Knarr::Request->new( protocol => 'openai', model => 'pt',
    messages => $msgs, raw => { model => 'pt', messages => $msgs },
    extra => { forward_headers => { 'X-Mode' => 'hang' } } );
  my $f = $passthrough->handle_chat_f( $session, $req );
  $loop->await($f);
  like( $f->failure, qr/Passthrough: upstream \Q$up\E\/v1\/chat\/completions timed out after 0.5s/,
    'handler passthrough: sync request fails with the timeout' );

  my $stream = $passthrough->handle_stream_f( $session, $req )->get;
  my $cf = $stream->next_chunk_f;
  $loop->await($cf);
  like( $cf->failure, qr/timed out after 0.5s without data/, 'handler passthrough: stream fails with the stall timeout' );
}

# --- A2A and ACP clients: a remote agent that never answers.
{
  my $session = Langertha::Knarr::Session->new( id => 's' );
  my $req = Langertha::Knarr::Request->new( protocol => 'openai', model => 'x', messages => $msgs );
  for my $h (
    Langertha::Knarr::Handler::A2AClient->new( url => "$up/", loop => $loop, timeout => 0.5 ),
    Langertha::Knarr::Handler::ACPClient->new( url => $up, agent_name => 'a', loop => $loop, timeout => 0.5 ),
  ) {
    my $start = time;
    my $f = $h->handle_chat_f( $session, $req );
    $loop->await($f);
    like( $f->failure, qr/upstream \Q$up\E\S* timed out after 0.5s/, ref($h) . ': fails with the timeout' );
    ok( time - $start < 3, ref($h) . ': not never' );
  }
}

# --- 0 disables: no timeout option reaches Net::Async::HTTP (it would read
#     0 as "expire now"); the defaults are 300s total and 120s stall.
{
  package RecordingHTTP;
  sub new { bless { calls => [] }, shift }
  sub do_request { my ($self, %a) = @_; push @{ $self->{calls} }, \%a; Future->done( HTTP::Response->new(200) ) }
}
{
  my $rec = RecordingHTTP->new;
  my $pt = Langertha::Knarr::Handler::Passthrough->new( upstreams => { openai => $up },
    timeout => 0, stall_timeout => 0, _http => $rec );
  my $r = HTTP::Request->new( POST => "$up/x" );
  $pt->_upstream_request_f( request => $r )->get;
  $pt->_upstream_request_f( request => $r, on_header => sub { sub {} } )->get;
  ok( !exists $_->{timeout} && !exists $_->{stall_timeout}, '0 disables: no timeout option' )
    for @{ $rec->{calls} };

  my $def = Langertha::Knarr::Handler::Passthrough->new( upstreams => { openai => $up }, _http => ( $rec = RecordingHTTP->new ) );
  $def->_upstream_request_f( request => $r )->get;
  $def->_upstream_request_f( request => $r, stream => 1 )->get;
  is( $rec->{calls}[0]{timeout}, 300, 'default: 300s total for a plain request' );
  is( $rec->{calls}[1]{stall_timeout}, 120, 'default: 120s stall for a stream' );
  ok( !exists $rec->{calls}[1]{timeout}, 'a stream gets no total timeout' );
}

# --- Config: upstream_timeout / upstream_stall_timeout, env fallback,
#     validation; routed engines get upstream_timeout as user_agent_timeout.
{
  my %base = ( models => {
    plain  => { engine => 'OpenAI', model => 'm1', api_key => 'k' },
    own    => { engine => 'OpenAI', model => 'm2', api_key => 'k', user_agent_timeout => 42 },
    nolimit => { engine => 'OpenAI', model => 'm3', api_key => 'k', user_agent_timeout => 0 },
  } );
  local $ENV{KNARR_UPSTREAM_TIMEOUT};
  local $ENV{KNARR_UPSTREAM_STALL_TIMEOUT};
  my $c = Langertha::Knarr::Config->new( data => { %base } );
  is( $c->upstream_timeout, 300, 'config: upstream_timeout defaults to 300' );
  is( $c->upstream_stall_timeout, 120, 'config: upstream_stall_timeout defaults to 120' );

  $ENV{KNARR_UPSTREAM_TIMEOUT} = '"60"';
  $ENV{KNARR_UPSTREAM_STALL_TIMEOUT} = '30';
  $c = Langertha::Knarr::Config->new( data => { %base } );
  is( $c->upstream_timeout, 60, 'config: KNARR_UPSTREAM_TIMEOUT' );
  is( $c->upstream_stall_timeout, 30, 'config: KNARR_UPSTREAM_STALL_TIMEOUT' );
  $c = Langertha::Knarr::Config->new( data => { %base, upstream_timeout => 90, upstream_stall_timeout => 0 } );
  is( $c->upstream_timeout, 90, 'config: the file wins over the env' );
  is( $c->upstream_stall_timeout, 0, 'config: 0 is kept (disabled)' );

  my $router = Langertha::Knarr::Router->new( config => $c );
  is( ( $router->resolve('plain') )[0]->user_agent_timeout, 90, 'router: engine gets upstream_timeout' );
  is( ( $router->resolve('own') )[0]->user_agent_timeout, 42, "router: the model's own user_agent_timeout wins" );
  ok( !( $router->resolve('nolimit') )[0]->has_user_agent_timeout, 'router: 0 leaves the engine without one' );

  my $bad = Langertha::Knarr::Config->new( data => { %base,
    upstream_timeout => 'soon', models => { %{ $base{models} },
      worse => { engine => 'OpenAI', user_agent_timeout => -1 } } } );
  my @errors = $bad->validate;
  ok( ( grep { /upstream_timeout 'soon' must be a number of seconds/ } @errors ), 'validate: bad upstream_timeout' );
  ok( ( grep { /Model 'worse': user_agent_timeout must be a number of seconds/ } @errors ), 'validate: bad user_agent_timeout' );
}

done_testing;
