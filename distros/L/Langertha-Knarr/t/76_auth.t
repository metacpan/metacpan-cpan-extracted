use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1 );
my $loop = IO::Async::Loop->new;

my $handler = Langertha::Knarr::Handler::Code->new( code => sub { 'authed-ok' } );

my $knarr = Langertha::Knarr->new(
  handler    => $handler,
  loop       => $loop,
  port       => 0,
  auth_token => 'sk-test-secret',
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;

my $http = Net::Async::HTTP->new;
$loop->add($http);

my $body = $json->encode({
  model => 'm', messages => [ { role => 'user', content => 'hi' } ],
});

# --- 1) No auth header → 401 ---
{
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 401, 'no auth → 401' );
}

# --- 2) Wrong Bearer token → 401 ---
{
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type'  => 'application/json' );
  $req->header( 'Authorization' => 'Bearer wrong' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 401, 'wrong bearer → 401' );
}

# --- 3) Correct Bearer token → 200 ---
{
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type'  => 'application/json' );
  $req->header( 'Authorization' => 'Bearer sk-test-secret' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'correct bearer → 200' );
  my $d = $json->decode($resp->decoded_content);
  is( $d->{choices}[0]{message}{content}, 'authed-ok', 'content delivered' );
}

# --- 4) Correct x-api-key → 200 ---
{
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->header( 'x-api-key'    => 'sk-test-secret' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'x-api-key → 200' );
}

# --- 5) Agent card stays anonymous even with auth set ---
{
  my $req = HTTP::Request->new( GET => "http://127.0.0.1:$port/.well-known/agent.json" );
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'agent card anonymous' );
}

# --- 6) When no auth_token configured, anything works ---
{
  my $open = Langertha::Knarr->new(
    handler => $handler,
    loop    => $loop,
    port    => 0,
  );
  $open->start;
  my $oport = $open->_server->read_handle->sockport;

  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$oport/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'no auth_token → open' );
}

done_testing;
