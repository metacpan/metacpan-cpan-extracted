use strict;
use warnings;

use Test::More tests => 1;
use IO::Socket::INET6;

#funny IPv6 addresses
my $srv = "dead:beef::1";
my $port = 6789;
my $srvFlow = 4321;

my $sck6 = IO::Socket::INET6->new(
    Domain  =>  AF_INET6,
    Proto   => 'tcp',
    LocalAddr    => $srv,
    LocalPort    => $port,
    LocalFlow   => $srvFlow,
    Listen  =>  1,
    ReuseAddr   =>  1
);

# TEST
ok(1, q{Testing that "sub configure" does not fail});

