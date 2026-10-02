use strict;
use warnings;
use Test2::V0;

# Maintainer decision 2026-09-29: since a model known only through
# auto_discover goes raw passthrough when the client protocol's upstream
# listed it, a client without its own provider key got the upstream's 401
# for it -- though the engine that listed the model holds Knarr's key (the
# Docker image under --from-env, where there is no models: section to pin
# it in). Now such a model passes through only when the request carries a
# provider key once Knarr's proxy key is taken out: Authorization for
# OpenAI, x-api-key or Authorization for Anthropic. Without one it is routed
# through its engine, with the engine's key. An unknown model still passes
# through either way (there is no engine to fall back to).
#
# Key-free: the passthrough upstream is a local server, the engines are
# offline LangerthaX fakes.

BEGIN {
  package LangerthaX::Engine::TestKnarrKeyless;
  use Future;
  use Langertha::Response;
  our @chats;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub url { $_[0]{url} }
  sub chat_model { $_[0]{model} }
  sub list_models { $_[0]{url} =~ m{/v1\z} ? [ 'gpt-disc' ] : [ 'claude-disc' ] }
  sub chat_f {
    my ($self) = @_;
    push @chats, { model => $self->{model}, api_key => $self->{api_key} };
    return Future->done( Langertha::Response->new( content => 'from-engine', raw => {} ) );
  }
  $INC{'LangerthaX/Engine/TestKnarrKeyless.pm'} = __FILE__;
}

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
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my %SYNC = (
  '/v1/messages'         => qq({"content":[{"text":"from-upstream","type":"text"}],"stop_reason":"end_turn"}),
  '/v1/chat/completions' => qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"from-upstream","role":"assistant"}}]}),
);
my %STREAM = (
  '/v1/messages'         => qq(event: content_block_delta\ndata: {"delta":{"text":"from-upstream","type":"text_delta"},"type":"content_block_delta"}\n\nevent: message_stop\ndata: {"type":"message_stop"}\n\n),
  '/v1/chat/completions' => qq(data: {"choices":[{"delta":{"content":"from-upstream"},"index":0}]}\n\ndata: [DONE]\n\n),
);

my @hits;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @hits, $req->path;
    if ( ( $req->body // '' ) =~ /"stream":true/ ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => 'text/event-stream' );
      $req->respond_chunk_header($head);
      $req->write_chunk( $STREAM{ $req->path } // '' );
      $req->write_chunk_eof;
      return;
    }
    my $body = $SYNC{ $req->path } // '{}';
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $PROXY_KEY = 'knarr-proxy-secret';

# Wired like `knarr start --from-env`: both endpoints are the passthrough
# upstreams of their protocol, and hold Knarr's own key.
my $config = Langertha::Knarr::Config->new( data => {
  auto_discover => 1,
  passthrough   => { anthropic => $up, openai => $up },
  models        => {
    anthropic => { engine => 'TestKnarrKeyless', url => $up,       api_key => 'sk-knarr-anthropic' },
    openai    => { engine => 'TestKnarrKeyless', url => "$up/v1", api_key => 'sk-knarr-openai' },
  },
} );
my $router = Langertha::Knarr::Router->new( config => $config );
my $pt = Langertha::Knarr::Handler::Passthrough->new( upstreams => $config->passthrough, loop => $loop );

my %server;
for my $auth ( 'keyed', 'open' ) {
  my $knarr = Langertha::Knarr->new(
    handler         => Langertha::Knarr::Handler::Router->new( router => $router, passthrough => $pt ),
    router          => $router,
    raw_passthrough => $pt,
    loop            => $loop,
    listen          => [ '127.0.0.1:0' ],
    ( $auth eq 'keyed' ? ( auth_token => $PROXY_KEY ) : () ),
  );
  $knarr->start;
  $server{$auth} = {
    port => $knarr->_server->read_handle->sockport,
    psgi => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %path = ( anthropic => '/v1/messages', openai => '/v1/chat/completions' );

sub send_chat {
  my ($transport, $auth, $protocol, $model, $stream, @headers) = @_;
  my $body = $json->encode({ model => $model, messages => [ { role => 'user', content => 'hi' } ],
    ( $protocol eq 'anthropic' ? ( max_tokens => 5 ) : () ),
    ( $stream ? ( stream => JSON::MaybeXS::true() ) : () ) });
  my @h = ( 'Content-Type' => 'application/json', @headers );
  @hits = (); @LangerthaX::Engine::TestKnarrKeyless::chats = ();
  my $s = $server{$auth};
  return $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$s->{port}$path{$protocol}", \@h, $body ) )->get
    : $s->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path{$protocol}", \@h, $body ) );
}

# label, auth, protocol, model, client headers, expected route, engine key
my @cases = (
  [ 'Anthropic, own x-api-key', 'keyed', anthropic => 'claude-disc',
    [ Authorization => "Bearer $PROXY_KEY", 'x-api-key' => 'sk-ant-own' ], 'raw' ],
  [ 'Anthropic, own OAuth token as Bearer', 'keyed', anthropic => 'claude-disc',
    [ 'x-api-key' => $PROXY_KEY, Authorization => 'Bearer oauth-own' ], 'raw' ],
  [ 'Anthropic, only the proxy key', 'keyed', anthropic => 'claude-disc',
    [ Authorization => "Bearer $PROXY_KEY" ], 'engine', 'sk-knarr-anthropic' ],
  [ 'Anthropic, only the proxy key, sent twice', 'keyed', anthropic => 'claude-disc',
    [ 'x-api-key' => $PROXY_KEY, 'x-api-key' => $PROXY_KEY ], 'engine', 'sk-knarr-anthropic' ],
  [ 'Anthropic, no key at all (open proxy)', 'open', anthropic => 'claude-disc',
    [], 'engine', 'sk-knarr-anthropic' ],
  [ 'OpenAI, own key as Bearer', 'keyed', openai => 'gpt-disc',
    [ 'x-api-key' => $PROXY_KEY, Authorization => 'Bearer sk-openai-own' ], 'raw' ],
  [ 'OpenAI, only the proxy key', 'keyed', openai => 'gpt-disc',
    [ 'x-api-key' => $PROXY_KEY ], 'engine', 'sk-knarr-openai' ],
  [ 'OpenAI, only x-api-key (not an OpenAI credential, open proxy)', 'open', openai => 'gpt-disc',
    [ 'x-api-key' => 'sk-something' ], 'engine', 'sk-knarr-openai' ],
  [ 'OpenAI, no key at all (open proxy)', 'open', openai => 'gpt-disc',
    [], 'engine', 'sk-knarr-openai' ],
  [ 'unknown model, only the proxy key', 'keyed', openai => 'nobody-knows',
    [ 'x-api-key' => $PROXY_KEY ], 'raw' ],
);

for my $transport ( 'native', 'psgi' ) {
  for my $stream ( 0, 1 ) {
    for my $case (@cases) {
      my ($label, $auth, $protocol, $model, $headers, $route, $engine_key) = @$case;
      my $tag = "$transport" . ( $stream ? '/stream' : '' ) . ": $label";
      my $resp = send_chat( $transport, $auth, $protocol, $model, $stream, @$headers );
      is( $resp->code, 200, "$tag: answered" );
      my $chats = [ @LangerthaX::Engine::TestKnarrKeyless::chats ];
      if ( $route eq 'raw' ) {
        is( \@hits, [ $path{$protocol} ], "$tag: raw passthrough to the upstream" );
        is( $chats, [], "$tag: no engine call" );
        like( $resp->content, qr/from-upstream/, "$tag: the upstream's answer" );
      }
      else {
        is( \@hits, [], "$tag: never reaches the passthrough upstream" );
        is( $chats, [ { model => $model, api_key => $engine_key } ],
          "$tag: routed through the engine that listed it, with its key" );
        like( $resp->content, qr/from-engine/, "$tag: the engine's answer" );
      }
    }
  }
}

done_testing;
