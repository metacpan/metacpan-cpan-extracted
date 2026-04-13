use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Passthrough;

# Mock tracer that records start/end events without needing Langfuse.
{
  package MockTracer;
  use Moo;
  has _enabled => ( is => 'ro', default => 1 );
  has events   => ( is => 'ro', default => sub { [] } );
  has _next_id => ( is => 'rw', default => 0 );
  sub start_trace {
    my ($self, %opts) = @_;
    return undef unless $self->_enabled;
    $self->_next_id( $self->_next_id + 1 );
    my $id = 'trace-' . $self->_next_id;
    push @{ $self->events }, { kind => 'start', id => $id, %opts };
    return { trace_id => $id, gen_id => "$id-gen", start_time => time() };
  }
  sub end_trace {
    my ($self, $info, %opts) = @_;
    return unless $info;
    push @{ $self->events }, { kind => 'end', id => $info->{trace_id}, %opts };
  }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Backend: a plain Knarr that returns known responses.
my $backend = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Code->new(
    code => sub {
      my ($s, $r) = @_;
      return "UPSTREAM: " . ($r->messages->[-1]{content} // '');
    },
    stream_code => sub {
      my @parts = ('UP', 'STREAM');
      return sub { @parts ? shift @parts : undef };
    },
  ),
  loop => $loop,
  port => 0,
);
$backend->start;
my $bport = $backend->_server->read_handle->sockport;
ok( $bport, "backend on port $bport" );

# --- Config with no models (everything goes to passthrough).
my $config = Langertha::Knarr::Config->new(
  data => {
    models  => {},
    default => undef,
    passthrough => {
      openai    => "http://127.0.0.1:$bport",
      anthropic => "http://127.0.0.1:$bport",
    },
  },
);

my $router = Langertha::Knarr::Router->new( config => $config );
my $passthrough = Langertha::Knarr::Handler::Passthrough->new(
  upstreams => $config->passthrough,
  loop      => $loop,
);

my $handler = Langertha::Knarr::Handler::Router->new(
  router      => $router,
  passthrough => $passthrough,
);

my $tracer = MockTracer->new;

my $front = Langertha::Knarr->new(
  handler         => $handler,
  loop            => $loop,
  port            => 0,
  router          => $router,
  raw_passthrough => $passthrough,
  tracing         => $tracer,
);
$front->start;
my $fport = $front->_server->read_handle->sockport;
ok( $fport, "front on port $fport" );

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post_json {
  my ($url, $body, %headers) = @_;
  my $req = HTTP::Request->new( POST => $url );
  $req->header( 'Content-Type' => 'application/json' );
  for my $h (keys %headers) {
    $req->header( $h => $headers{$h} );
  }
  $req->content( $json->encode($body) );
  return $http->do_request( request => $req )->get;
}

# --- 1) Raw passthrough routes unknown models (sync) ---
{
  ok( $router->is_passthrough_model('claude-opus-4-6'), 'unknown model is passthrough' );

  my $resp = post_json(
    "http://127.0.0.1:$fport/v1/chat/completions",
    { model => 'gpt-mystery', messages => [ { role => 'user', content => 'hello' } ] },
  );
  is( $resp->code, 200, 'raw passthrough sync 200' );
  my $d = $json->decode( $resp->decoded_content );
  # Raw passthrough forwards the backend's response as-is (OpenAI format)
  is( $d->{choices}[0]{message}{content}, 'UPSTREAM: hello', 'raw passthrough content' );
}

# --- 2) Raw passthrough creates Langfuse trace ---
{
  my $event_count = scalar @{ $tracer->events };
  ok( $event_count >= 2, "tracer has events ($event_count)" );

  my $start = $tracer->events->[0];
  is( $start->{kind}, 'start', 'first event is start' );
  is( $start->{engine}, 'passthrough', 'engine tagged as passthrough' );
  is( $start->{model}, 'gpt-mystery', 'model recorded' );
  is( $start->{format}, 'openai', 'format recorded' );

  my $end = $tracer->events->[1];
  is( $end->{kind}, 'end', 'second event is end' );
  is( $end->{id}, $start->{id}, 'end matches start id' );
}

# --- 3) Raw passthrough streaming ---
{
  $tracer->events->@* = ();  # reset

  my $resp = post_json(
    "http://127.0.0.1:$fport/v1/chat/completions",
    { model => 'gpt-unknown', messages => [ { role => 'user', content => 'stream' } ],
      stream => JSON::MaybeXS::true() },
  );
  is( $resp->code, 200, 'raw passthrough stream 200' );
  like( $resp->decoded_content, qr/UP/, 'stream chunk present' );
  like( $resp->decoded_content, qr/STREAM/, 'stream chunk 2 present' );

  # Trace was created for streaming too
  ok( scalar @{ $tracer->events } >= 2, 'tracer has stream events' );
  is( $tracer->events->[0]{kind}, 'start', 'stream trace start' );
  is( $tracer->events->[0]{model}, 'gpt-unknown', 'stream model recorded' );
  is( $tracer->events->[-1]{kind}, 'end', 'stream trace end' );
}

# --- 4) Anthropic raw passthrough with auth headers ---
{
  $tracer->events->@* = ();

  my $resp = post_json(
    "http://127.0.0.1:$fport/v1/messages",
    { model => 'claude-test', messages => [ { role => 'user', content => 'hi' } ] },
    'x-api-key'        => 'sk-ant-test-key',
    'anthropic-version' => '2023-06-01',
  );
  is( $resp->code, 200, 'anthropic raw passthrough 200' );

  is( $tracer->events->[0]{format}, 'anthropic', 'anthropic format traced' );
  is( $tracer->events->[0]{model}, 'claude-test', 'anthropic model traced' );
}

# --- 5) Without tracing: still works (no crash) ---
{
  my $front_no_trace = Langertha::Knarr->new(
    handler         => $handler,
    loop            => $loop,
    port            => 0,
    router          => $router,
    raw_passthrough => $passthrough,
    # no tracing attribute
  );
  $front_no_trace->start;
  my $np = $front_no_trace->_server->read_handle->sockport;

  my $resp = post_json(
    "http://127.0.0.1:$np/v1/chat/completions",
    { model => 'gpt-test', messages => [ { role => 'user', content => 'no trace' } ] },
  );
  is( $resp->code, 200, 'passthrough without tracing works' );
  my $d = $json->decode( $resp->decoded_content );
  is( $d->{choices}[0]{message}{content}, 'UPSTREAM: no trace', 'content correct without tracing' );
}

done_testing;
