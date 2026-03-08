use strict;
use warnings;
use Test::More;

use IO::Socket::HappyEyeballs;

my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost => 'this-host-does-not-exist.invalid',
  PeerPort => 80,
  Timeout  => 2,
);

ok(!$sock, 'connection to unresolvable host fails');
like($@, qr/(?:no addresses found|getaddrinfo failed)/, 'error message set');

done_testing;
