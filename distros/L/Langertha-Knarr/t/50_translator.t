use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::A2AClient;
use Langertha::Knarr::Handler::ACPClient;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Backend: a Steerboard with Code handler, exposes ALL protocols ---
my $backend_handler = Langertha::Knarr::Handler::Code->new(
  code => sub {
    my ($s, $r) = @_;
    my $u = $r->messages->[-1] // {};
    return "BACKEND-SAW: " . ( $u->{content} // '' );
  },
);
my $backend = Langertha::Knarr->new(
  handler => $backend_handler,
  loop    => $loop,
  port    => 0,
);
$backend->start;
my $backend_port = $backend->_server->read_handle->sockport;
ok( $backend_port, "backend on $backend_port" );

# --- Translator A: A2AClient pointing at backend, exposed via OpenAI ---
my $a2a_handler = Langertha::Knarr::Handler::A2AClient->new(
  url  => "http://127.0.0.1:$backend_port/",
  loop => $loop,
);
my $translator_a2a = Langertha::Knarr->new(
  handler => $a2a_handler,
  loop    => $loop,
  port    => 0,
);
$translator_a2a->start;
my $tA_port = $translator_a2a->_server->read_handle->sockport;

# --- Translator B: ACPClient pointing at backend, exposed via OpenAI ---
my $acp_handler = Langertha::Knarr::Handler::ACPClient->new(
  url        => "http://127.0.0.1:$backend_port",
  agent_name => 'demo',
  loop       => $loop,
);
my $translator_acp = Langertha::Knarr->new(
  handler => $acp_handler,
  loop    => $loop,
  port    => 0,
);
$translator_acp->start;
my $tB_port = $translator_acp->_server->read_handle->sockport;

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub openai_chat {
  my ($port, $text) = @_;
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json->encode({
    model => 'm',
    messages => [ { role => 'user', content => $text } ],
  }));
  my $resp = $http->do_request( request => $req )->get;
  return ( $resp->code, $json->decode($resp->decoded_content) );
}

# OpenAI -> A2AClient -> A2A backend
{
  my ($code, $data) = openai_chat( $tA_port, 'ping1' );
  is( $code, 200, 'OpenAI->A2A 200' );
  is( $data->{choices}[0]{message}{content}, 'BACKEND-SAW: ping1', 'A2A round trip' );
}

# OpenAI -> ACPClient -> ACP backend
{
  my ($code, $data) = openai_chat( $tB_port, 'ping2' );
  is( $code, 200, 'OpenAI->ACP 200' );
  is( $data->{choices}[0]{message}{content}, 'BACKEND-SAW: ping2', 'ACP round trip' );
}

done_testing;
