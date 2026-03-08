use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_HAPPYEYEBALLS_LIVE}) {
  plan skip_all => 'set TEST_HAPPYEYEBALLS_LIVE=1 for live dual-stack tests';
}

use IO::Socket::HappyEyeballs;
use Socket qw(AF_INET AF_INET6);

IO::Socket::HappyEyeballs->clear_cache;

# Connect to a well-known dual-stack host
my $host = $ENV{TEST_HAPPYEYEBALLS_HOST} || 'www.google.com';

my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost => $host,
  PeerPort => 80,
  Timeout  => 10,
);

ok($sock, "connected to $host") or diag("Failed: $@");

SKIP: {
  skip "no connection to $host", 3 unless $sock;

  ok($sock->connected, 'socket is connected');

  my $family = $sock->sockdomain;
  ok($family == AF_INET || $family == AF_INET6,
    'connected via IPv4 or IPv6 (family=' . $family . ')');

  my $family_name = $family == AF_INET6 ? 'IPv6' : 'IPv4';
  diag("Connected to $host via $family_name");

  # Test that sending data works
  print $sock "HEAD / HTTP/1.0\r\nHost: $host\r\n\r\n";
  my $response = <$sock>;
  like($response, qr/^HTTP/, 'received HTTP response');

  $sock->close;
}

done_testing;
