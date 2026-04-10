use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $handler = Langertha::Knarr::Handler::Code->new(
  code => sub { 'multi-listen-ok' },
);

# Allocate two free ports up-front by binding then closing — this lets us
# pass concrete ports to Knarr and connect to known addresses afterward.
sub free_port {
  require IO::Socket::INET;
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "free_port: $!";
  my $p = $s->sockport;
  $s->close;
  return $p;
}
my @ports = ( free_port(), free_port() );
isnt( $ports[0], $ports[1], 'two distinct free ports allocated' );

my $knarr = Langertha::Knarr->new(
  handler => $handler,
  loop    => $loop,
  listen  => [
    { host => '127.0.0.1', port => $ports[0] },
    "127.0.0.1:$ports[1]",
  ],
);
$knarr->start;
ok( $knarr->_server, 'server bound on multiple addresses' );

my $http = Net::Async::HTTP->new;
$loop->add($http);

# Hit BOTH ports — both should answer with the same handler.
for my $port (@ports) {
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json->encode({
    model => 'm',
    messages => [ { role => 'user', content => 'hi' } ],
  }));
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, "port $port responds 200" );
  my $d = $json->decode($resp->decoded_content);
  is( $d->{choices}[0]{message}{content}, 'multi-listen-ok', "port $port content" );
}

# String form parsing
{
  my $k = Langertha::Knarr->new(
    handler => $handler,
    listen  => [ '0.0.0.0:9999', { host => '127.0.0.1', port => 8888 } ],
  );
  my @addrs = $k->_listen_addrs;
  is( scalar @addrs, 2, 'two parsed addrs' );
  is( $addrs[0]{host}, '0.0.0.0', 'string host parsed' );
  is( $addrs[0]{port}, 9999,      'string port parsed' );
  is( $addrs[1]{host}, '127.0.0.1', 'hash host' );
  is( $addrs[1]{port}, 8888,        'hash port' );
}

# Default builder from host/port
{
  my $k = Langertha::Knarr->new(
    handler => $handler,
    host    => '0.0.0.0',
    port    => 12345,
  );
  my @addrs = $k->_listen_addrs;
  is( scalar @addrs, 1, 'default single addr' );
  is( $addrs[0]{host}, '0.0.0.0', 'default host' );
  is( $addrs[0]{port}, 12345,     'default port' );
}

done_testing;
