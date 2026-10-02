use strict;
use warnings;
use Test2::V0;

# Regression: whether a discovered model was listed by the passthrough
# upstream of the client's protocol compared scheme, host and port only. A
# gateway that serves several providers under paths of one host (Cloudflare
# AI Gateway style: .../gw/openai, .../gw/anthropic, .../gw/groq) made every
# model discovered through it count as the upstream's own: a Groq model
# asked for over the OpenAI protocol went raw to .../gw/openai and got a
# 404, its engine never asked. Now the paths must match too, apart from an
# engine's trailing /v1 (https://api.openai.com/v1 is still the upstream
# https://api.openai.com); host case and default ports stay normalised.
#
# Key-free: the gateway is a local server, the engines are offline
# LangerthaX fakes.

BEGIN {
  package LangerthaX::Engine::TestKnarrGateway;
  use Future;
  use Langertha::Response;
  our @chats;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub url { $_[0]{url} }
  sub chat_model { $_[0]{model} }
  sub list_models { $_[0]{url} =~ m{/groq/} ? [ 'llama-3.3-70b' ] : [ 'gpt-gw' ] }
  sub chat_f {
    my ($self) = @_;
    push @chats, $self->{model};
    return Future->done( Langertha::Response->new( content => 'from-engine', raw => {} ) );
  }
  $INC{'LangerthaX/Engine/TestKnarrGateway.pm'} = __FILE__;
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

# is_upstream_for on its own.
{
  my $gw = 'https://gateway.ai.cloudflare.com/v1/acct/gw';
  my $pt = Langertha::Knarr::Handler::Passthrough->new( upstreams => {
    openai    => "$gw/openai",
    anthropic => "$gw/anthropic",
    ollama    => 'http://localhost:11434',
  } );
  my $plain = Langertha::Knarr::Handler::Passthrough->new( upstreams => {
    openai    => 'https://api.openai.com',
    anthropic => 'https://api.anthropic.com/',
  } );
  my @cases = (
    [ $pt,    anthropic => "$gw/openai",                                   0, 'another path on the gateway' ],
    [ $pt,    openai    => "$gw/groq",                                     0, 'the gateway\'s Groq path' ],
    [ $pt,    openai    => "$gw/groq/v1",                                  0, 'the gateway\'s Groq path with /v1' ],
    [ $pt,    openai    => "$gw/openaiX/v1",                               0, 'a path that only starts like it' ],
    [ $pt,    openai    => "$gw/openai",                                   1, 'the same path' ],
    [ $pt,    openai    => "$gw/openai/v1",                                1, 'the same path plus /v1' ],
    [ $pt,    openai    => "$gw/openai/v1/",                               1, 'plus /v1/' ],
    [ $pt,    openai    => 'https://gateway.ai.cloudflare.com:443/v1/acct/gw/openai', 1, 'explicit default port' ],
    [ $pt,    openai    => 'https://GATEWAY.ai.cloudflare.com/v1/acct/gw/openai',     1, 'host case' ],
    [ $pt,    ollama    => 'http://127.0.0.1:11434/v1',                    0, 'another host' ],
    [ $pt,    ollama    => 'http://LOCALHOST:11434/v1',                    1, 'OllamaOpenAI /v1 on the Ollama upstream' ],
    [ $pt,    ollama    => 'http://localhost:11434',                       1, 'native Ollama on the Ollama upstream' ],
    [ $plain, openai    => 'https://api.openai.com/v1',                    1, 'OpenAI engine on api.openai.com' ],
    [ $plain, anthropic => 'https://api.anthropic.com',                    1, 'Anthropic engine, upstream with trailing slash' ],
    [ $plain, openai    => 'https://api.openai.com/other/v1',              0, 'a sub-path of a root upstream' ],
    [ $plain, openai    => 'http://api.openai.com/v1',                     0, 'another scheme' ],
  );
  for my $c (@cases) {
    my ($p, $protocol, $url, $want, $label) = @$c;
    is( $p->is_upstream_for( $protocol, $url ), $want, "is_upstream_for $protocol: $label" );
  }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# The gateway: answers on its OpenAI path, 404 anywhere else.
my $OPENAI = qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"from-gateway","role":"assistant"}}]});
my @hits;
my $gateway = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @hits, $req->path;
    my ($code, $body) = $req->path eq '/gw/openai/v1/chat/completions'
      ? ( 200, $OPENAI ) : ( 404, '{"error":"model not found on this backend"}' );
    my $resp = HTTP::Response->new($code);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($gateway);
$gateway->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $gw = 'http://127.0.0.1:' . $gateway->read_handle->sockport . '/gw';

my $config = Langertha::Knarr::Config->new( data => {
  auto_discover => 1,
  passthrough   => { openai => "$gw/openai" },
  models        => {
    groq   => { engine => 'TestKnarrGateway', url => "$gw/groq/v1" },
    openai => { engine => 'TestKnarrGateway', url => "$gw/openai/v1" },
  },
} );
my $router = Langertha::Knarr::Router->new( config => $config );
my $pt = Langertha::Knarr::Handler::Passthrough->new( upstreams => $config->passthrough, loop => $loop );
my $knarr = Langertha::Knarr->new(
  handler         => Langertha::Knarr::Handler::Router->new( router => $router, passthrough => $pt ),
  router          => $router,
  raw_passthrough => $pt,
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

sub send_chat {
  my ($transport, $model) = @_;
  my $body = $json->encode({ model => $model, messages => [ { role => 'user', content => 'hi' } ] });
  my @h = ( 'Content-Type' => 'application/json', Authorization => 'Bearer sk-client-own' );
  @hits = (); @LangerthaX::Engine::TestKnarrGateway::chats = ();
  return $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions", \@h, $body ) )->get
    : $psgi->request( HTTP::Request->new( POST => 'http://localhost/v1/chat/completions', \@h, $body ) );
}

for my $transport ( 'native', 'psgi' ) {
  {
    my $resp = send_chat( $transport, 'llama-3.3-70b' );
    is( $resp->code, 200, "$transport: Groq model discovered on the gateway answered" );
    like( $resp->content, qr/from-engine/, "$transport: Groq model goes through its engine" );
    is( \@hits, [], "$transport: Groq model never sent to the gateway's OpenAI path" );
    is( \@LangerthaX::Engine::TestKnarrGateway::chats, [ 'llama-3.3-70b' ], "$transport: the Groq engine answered" );
  }
  {
    my $resp = send_chat( $transport, 'gpt-gw' );
    is( $resp->code, 200, "$transport: OpenAI model discovered on the gateway answered" );
    is( $resp->content, $OPENAI, "$transport: OpenAI model passes through byte for byte" );
    is( \@hits, [ '/gw/openai/v1/chat/completions' ], "$transport: to the gateway's OpenAI path" );
    is( \@LangerthaX::Engine::TestKnarrGateway::chats, [], "$transport: no engine call" );
  }
}

done_testing;
