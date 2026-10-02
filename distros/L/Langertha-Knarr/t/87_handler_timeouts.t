use strict;
use warnings;
use Test2::V0;

# Regression (k36): an upstream timeout that reaches the client through the
# handler chain -- a routed engine (core k278 fails the future with the
# Net::Async::HTTP category 'timeout' / 'stall_timeout' as its second value)
# or Handler::Passthrough (knarr's UpstreamHTTP role, same category) -- lost
# that category on its way through Handler::Router and the Tracing /
# RequestLog decorators and reached the client as a generic 500, or
# mid-stream as an '[error: ...]' text chunk the client reads as model
# output. The category now survives the chain: a timeout answers 504 in the
# client protocol's error shape, or ends a started stream with the
# protocol's error frame, like the raw passthrough (k35). Any other failure
# keeps its 500 / '[error: ...]' answer. A core without k278 has no timeout
# on its async requests, so the routed-engine cases need a core with
# _async_do_request_f; the Handler::Passthrough cases run on any core.

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
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;
use Langertha::Knarr::PSGI;
use Langertha::Engine::OpenAI;

my $core_times_out = Langertha::Engine::OpenAI->can('_async_do_request_f') ? 1 : 0;

{
  package RecordingTracer;
  sub new { bless { ends => [] }, shift }
  sub start_trace { return { trace_id => 't' } }
  sub end_trace { my ($self, $info, %opts) = @_; push @{ $self->{ends} }, \%opts }
}
{
  package RecordingLog;
  sub new { bless { ends => [] }, shift }
  sub start_request { return {} }
  sub end_request { my ($self, $handle, %opts) = @_; push @{ $self->{ends} }, \%opts }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Upstream. The model in the request body picks the misbehavior; the
#     requests it never answers are kept so their connections stay open.
my @held;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my $model = eval { $json->decode( $req->body )->{model} } // '';
    push @held, $req;
    return if $model =~ /hang/;
    if ( $model =~ /broken/ ) {
      my $resp = HTTP::Response->new(500);
      $resp->protocol('HTTP/1.1');
      $resp->content('{"error":{"message":"upstream exploded"}}');
      $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $resp->content );
      return $req->respond($resp);
    }
    # stall: the headers and one whole frame, then silence.
    my $ctype = $req->path eq '/api/chat' ? 'application/x-ndjson' : 'text/event-stream';
    my $head = HTTP::Response->new(200);
    $head->protocol('HTTP/1.1');
    $head->header( 'Content-Type' => $ctype );
    $req->respond_chunk_header($head);
    $req->write_chunk( {
      '/v1/chat/completions' => qq(data: {"choices":[{"delta":{"content":"a"},"index":0}]}\n\n),
      '/v1/messages'         => qq(event: content_block_delta\ndata: {"delta":{"text":"a","type":"text_delta"},"type":"content_block_delta"}\n\n),
      '/api/chat'            => qq({"done":false,"message":{"content":"a"}}\n),
    }->{ $req->path } );
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

# Configured models go to an OpenAI engine on the upstream (1s timeout, the
# engine's user_agent_timeout is an Int); anything else to Handler::Passthrough.
my $config = Langertha::Knarr::Config->new( data => {
  upstream_timeout => 1,
  models => {
    map { ( "routed-$_" => { engine => 'OpenAI', url => "$up/v1", api_key => 'k', model => "routed-$_" } ) }
      qw( hang stall broken )
  },
} );
my $tracer = RecordingTracer->new;
my $rlog   = RecordingLog->new;
my $handler = Langertha::Knarr::Handler::RequestLog->new(
  request_log => $rlog,
  wrapped     => Langertha::Knarr::Handler::Tracing->new(
    tracing => $tracer,
    wrapped => Langertha::Knarr::Handler::Router->new(
      router      => Langertha::Knarr::Router->new( config => $config ),
      passthrough => Langertha::Knarr::Handler::Passthrough->new(
        upstreams     => { openai => $up, anthropic => $up, ollama => $up },
        loop          => $loop,
        timeout       => 1,
        stall_timeout => 1,
      ),
    ),
  ),
);
my $knarr = Langertha::Knarr->new(
  handler => $handler,
  loop    => $loop,
  listen  => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my $client = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($client);

my %path = ( openai => '/v1/chat/completions', anthropic => '/v1/messages', ollama => '/api/chat' );

sub send_request {
  my ($transport, $proto, $model, $stream) = @_;
  my $body = { model => $model, messages => [ { role => 'user', content => 'hi' } ],
    stream => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false() };
  $body->{max_tokens} = 5 if $proto eq 'anthropic';
  my @h = ( 'Content-Type' => 'application/json' );
  my $start = time;
  my $resp = $transport eq 'native'
    ? $client->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$port$path{$proto}", \@h, $json->encode($body) ), timeout => 10 )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path{$proto}", \@h, $json->encode($body) ) );
  return ( $resp, time - $start );
}

# The client protocol's error shape, carrying the timeout.
# The body as JSON, or as the text it is (a die under Plack::Test is text).
sub decoded { my ($resp) = @_; my $d = eval { $json->decode( $resp->content ) }; return $d // $resp->content }

my %error_shape = (
  openai    => sub { hash { field error => hash { field message => match qr/timed out after 1s/; end }; end } },
  anthropic => sub { hash { field type => 'error';
    field error => hash { field type => 'timeout_error'; field message => match qr/timed out after 1s/; end }; end } },
  ollama    => sub { hash { field error => match qr/timed out after 1s/; end } },
);
# The protocol's stream error frame, as the last thing on the stream.
my %error_frame = (
  openai    => qr/data: \{"error":\{"message":"[^"]*timed out after 1s[^"]*"\}\}\n\n\z/,
  anthropic => qr/event: error\ndata: \{"error":\{"message":"[^"]*timed out after 1s[^"]*","type":"timeout_error"\},"type":"error"\}\n\n\z/,
  ollama    => qr/\n?\{"error":"[^"]*timed out after 1s[^"]*"\}\n\z/,
);
my %first_delta = (
  openai    => qr/"content":"a"/,
  anthropic => qr/"text":"a"/,
  ollama    => qr/"content":"a"/,
);

my @paths = ( [ passthrough => 'pt' ] );
push @paths, [ routed => 'routed' ] if $core_times_out;

for my $p (@paths) {
  my ($via, $prefix) = @$p;
  for my $proto (qw( openai anthropic ollama )) {
    # --- No answer: 504 in the protocol's shape (native and PSGI alike).
    for my $transport (qw( native psgi )) {
      my $label = "$via $transport $proto sync, no answer";
      my ($resp, $took) = send_request( $transport, $proto, "$prefix-hang", 0 );
      is( $resp->code, 504, "$label: 504" );
      is( decoded($resp), $error_shape{$proto}->(), "$label: protocol's error shape" );
      ok( $took < 5, "$label: answered after the timeout (${took}s)" );
    }

    # --- Stream, no answer. Natively the stream's headers are already out:
    #     the protocol's error frame ends it, no '[error: ...]' text chunk.
    #     PSGI buffers the stream, nothing is out yet: 504.
    {
      my ($resp, $took) = send_request( 'native', $proto, "$prefix-hang", 1 );
      is( $resp->code, 200, "$via native $proto stream, no answer: the stream had started" );
      like( $resp->content, $error_frame{$proto}, "$via native $proto stream, no answer: ends with the error frame" );
      unlike( $resp->content, qr/\[error:/, "$via native $proto stream, no answer: no error text chunk" );
      ok( $took < 5, "$via native $proto stream, no answer: closed after the timeout (${took}s)" );

      my ($presp) = send_request( 'psgi', $proto, "$prefix-hang", 1 );
      is( $presp->code, 504, "$via psgi $proto stream, no answer: 504" );
      is( decoded($presp), $error_shape{$proto}->(), "$via psgi $proto stream, no answer: protocol's error shape" );
    }

    # --- Stream that stops after its first delta.
    {
      my ($resp, $took) = send_request( 'native', $proto, "$prefix-stall", 1 );
      is( $resp->code, 200, "$via native $proto stall: 200" );
      like( $resp->content, $first_delta{$proto}, "$via native $proto stall: the first delta went out" );
      like( $resp->content, $error_frame{$proto}, "$via native $proto stall: then the error frame" );
      unlike( $resp->content, qr/\[error:/, "$via native $proto stall: no error text chunk" );
      ok( $took < 5, "$via native $proto stall: closed after the stall timeout (${took}s)" );

      my ($presp) = send_request( 'psgi', $proto, "$prefix-stall", 1 );
      is( $presp->code, 504, "$via psgi $proto stall: 504" );
      is( decoded($presp), $error_shape{$proto}->(), "$via psgi $proto stall: protocol's error shape" );
    }
  }
}

# --- The decorators saw the timeout and recorded it as the request's error.
ok( ( grep { ( $_->{error} // '' ) =~ /timed out after 1s/ } @{ $tracer->{ends} } ),
  'Tracing decorator: the timeout is the recorded error' );
ok( ( grep { ( $_->{error} // '' ) =~ /timed out after 1s/ } @{ $rlog->{ends} } ),
  'RequestLog decorator: the timeout is the recorded error' );

# --- Any other failure keeps its answer: 500 and, mid-stream, the text chunk.
SKIP: {
  skip 'routed engine: core without k278', 3 unless $core_times_out;
  my ($resp) = send_request( 'native', 'openai', 'routed-broken', 0 );
  is( $resp->code, 500, 'other failure, sync: still 500' );
  like( decoded($resp)->{error}{message}, qr/500/, 'other failure, sync: its message' );
  ($resp) = send_request( 'native', 'openai', 'routed-broken', 1 );
  like( $resp->content, qr/\[error: /, 'other failure, stream: still the error text chunk' );
}

note 'routed-engine cases skipped: core without k278 timeouts' unless $core_times_out;

done_testing;
