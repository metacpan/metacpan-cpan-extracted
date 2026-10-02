use strict;
use warnings;
use Test2::V0;

# Regression (k41): with raw passthrough configured, every model the router
# did not configure went to the passthrough -- whatever protocol the client
# spoke. Passthrough upstreams exist per protocol (openai, anthropic,
# ollama); for a protocol without one (Ollama under `passthrough: true`,
# A2A, ACP, AG-UI always) Handler::Passthrough died looking up the upstream
# URL, and the default engine was never tried (under --from-env with
# OPENAI_API_KEY, `default: OpenAI` was dead config). Now:
#
#   - raw passthrough only when an upstream exists for the client protocol;
#   - otherwise the default engine;
#   - with neither, 404 in the client protocol's error shape -- not a 500
#     carrying a Perl die message.
#
# Key-free: the "upstream" is a local server, the default engine an OpenAI
# engine pointed at it.

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

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Upstream: /pt/... is the raw passthrough upstream, /engine/... the
#     default engine's endpoint. Every chat request is recorded by path.
my @hits;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my $path = $req->path;
    my $body = eval { $json->decode( $req->body ) } // {};
    my ( $code, $ctype, $content ) = ( 404, 'application/json', '{"error":{"message":"no such path"}}' );
    if ( $path =~ m{/chat/completions\z} ) {
      push @hits, $path;
      my $who = $path =~ m{\A/pt/} ? 'passthrough' : 'engine';
      $code = 200;
      if ( $body->{stream} ) {
        $ctype   = 'text/event-stream';
        $content = qq(data: {"choices":[{"delta":{"content":"from-$who"},"index":0}]}\n\n)
          . qq(data: {"choices":[{"delta":{},"finish_reason":"stop","index":0}]}\n\n)
          . "data: [DONE]\n\n";
      }
      else {
        $content = $json->encode({
          id => 'c1', object => 'chat.completion', model => $body->{model} // 'm',
          choices => [ { index => 0, finish_reason => 'stop',
            message => { role => 'assistant', content => "from-$who" } } ],
          usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
        });
      }
    }
    my $resp = HTTP::Response->new($code);
    $resp->protocol('HTTP/1.1');
    $resp->content($content);
    $resp->header( 'Content-Type' => $ctype, 'Content-Length' => length $content );
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $client = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($client);

# A Knarr wired like `knarr start`: the Passthrough handler is both the raw
# passthrough and Handler::Router's fallback; Tracing wraps the chain, so a
# failure category must survive a decorator.
{
  package NullTracer;
  sub new { bless {}, shift }
  sub start_trace { return { trace_id => 't' } }
  sub end_trace { }
}
sub build_knarr {
  my (%opt) = @_;
  my $config = Langertha::Knarr::Config->new( data => {
    auto_discover => 0,
    models        => {},
    ( $opt{default} ? ( default => { engine => 'OpenAI', url => "$up/engine/v1", api_key => 'k' } ) : () ),
  } );
  my $router = Langertha::Knarr::Router->new( config => $config );
  my $pt = $opt{passthrough} ? Langertha::Knarr::Handler::Passthrough->new(
    upstreams => $opt{passthrough}, loop => $loop, timeout => 5, stall_timeout => 5,
  ) : undef;
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    tracing => NullTracer->new,
    wrapped => Langertha::Knarr::Handler::Router->new(
      router => $router, ( $pt ? ( passthrough => $pt ) : () ),
    ),
  );
  my $knarr = Langertha::Knarr->new(
    handler => $handler,
    loop    => $loop,
    listen  => [ '127.0.0.1:0' ],
    router  => $router,
    ( $pt ? ( raw_passthrough => $pt ) : () ),
  );
  $knarr->start;
  return {
    port => $knarr->_server->read_handle->sockport,
    psgi => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

my %path = (
  openai => '/v1/chat/completions', anthropic => '/v1/messages', ollama => '/api/chat',
  a2a => '/', acp => '/runs', agui => '/awp',
);

sub body_for {
  my ($proto, $model, $stream) = @_;
  my $msgs = [ { role => 'user', content => 'hi' } ];
  return {
    a2a  => { jsonrpc => '2.0', id => 1, method => $stream ? 'tasks/sendSubscribe' : 'tasks/send',
      params => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] } } },
    acp  => { agent_name => $model, mode => $stream ? 'stream' : 'sync',
      input => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ] },
    agui => { threadId => 'th1', runId => 'r1', model => $model, messages => $msgs },
  }->{$proto} // {
    model => $model, messages => $msgs, max_tokens => 5,
    stream => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
  };
}

sub send_request {
  my ($k, $transport, $proto, $model, $stream) = @_;
  my @h = ( 'Content-Type' => 'application/json' );
  my $content = $json->encode( body_for( $proto, $model, $stream ) );
  @hits = ();
  return $transport eq 'native'
    ? $client->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$k->{port}$path{$proto}", \@h, $content ), timeout => 10 )->get
    : $k->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path{$proto}", \@h, $content ) );
}

sub decoded { my ($resp) = @_; my $d = eval { $json->decode( $resp->content ) }; return $d // $resp->content }

# The 404 in each protocol's error shape, naming the model and no Perl.
my $not_found = qr/\A(?!.* line \d+).*Model 'mystery' is not configured/s;
my %error_shape = (
  openai    => hash { field error => hash { field message => match $not_found; end }; end },
  anthropic => hash { field type => 'error';
    field error => hash { field type => 'not_found_error'; field message => match $not_found; end }; end },
  ollama    => hash { field error => match $not_found; end },
);

# --- 1. passthrough for openai only, a default engine -----------------------
my $with_default = build_knarr( passthrough => { openai => "$up/pt" }, default => 1 );

for my $via (qw( native psgi )) {
  for my $stream ( 0, 1 ) {
    my $what = "$via ".( $stream ? 'stream' : 'sync' );

    my $resp = send_request( $with_default, $via, 'openai', 'mystery', $stream );
    is( $resp->code, 200, "$what openai: unknown model answered" );
    is( [@hits], [ '/pt/v1/chat/completions' ], "$what openai: still raw passthrough" );

    for my $proto (qw( ollama anthropic acp )) {
      $resp = send_request( $with_default, $via, $proto, 'mystery', $stream );
      is( $resp->code, 200, "$what $proto: no upstream for the protocol, answered" )
        or diag $resp->content;
      is( [@hits], [ '/engine/v1/chat/completions' ], "$what $proto: by the default engine" );
      like( $resp->content, qr/from-engine/, "$what $proto: the engine's answer" );
    }

    $resp = send_request( $with_default, $via, 'a2a', undef, $stream );
    is( $resp->code, 200, "$what a2a: answered" ) or diag $resp->content;
    is( [@hits], [ '/engine/v1/chat/completions' ], "$what a2a: by the default engine" );
  }
  my $resp = send_request( $with_default, $via, 'agui', 'mystery', 1 );
  is( $resp->code, 200, "$via agui: answered" ) or diag $resp->content;
  is( [@hits], [ '/engine/v1/chat/completions' ], "$via agui: by the default engine" );
}

# --- 2. passthrough for openai only, no default engine ----------------------
my $no_default = build_knarr( passthrough => { openai => "$up/pt" } );

for my $via (qw( native psgi )) {
  for my $stream ( 0, 1 ) {
    my $what = "$via ".( $stream ? 'stream' : 'sync' );

    my $resp = send_request( $no_default, $via, 'openai', 'mystery', $stream );
    is( $resp->code, 200, "$what openai: raw passthrough unaffected" );
    is( [@hits], [ '/pt/v1/chat/completions' ], "$what openai: reached the upstream" );

    for my $proto (qw( ollama anthropic )) {
      $resp = send_request( $no_default, $via, $proto, 'mystery', $stream );
      is( $resp->code, 404, "$what $proto: nothing serves the model: 404" );
      is( decoded($resp), $error_shape{$proto}, "$what $proto: in the protocol's error shape" );
      is( [@hits], [], "$what $proto: nothing was sent upstream" );
    }
  }
}

# --- 3. no passthrough, no default engine -----------------------------------
my $bare = build_knarr();

for my $via (qw( native psgi )) {
  for my $stream ( 0, 1 ) {
    my $what = "$via ".( $stream ? 'stream' : 'sync' );
    for my $proto (qw( openai ollama )) {
      my $resp = send_request( $bare, $via, $proto, 'mystery', $stream );
      is( $resp->code, 404, "$what $proto without passthrough: 404, not a 500" );
      is( decoded($resp), $error_shape{$proto}, "$what $proto without passthrough: protocol's error shape" );
    }
  }
}

done_testing;
