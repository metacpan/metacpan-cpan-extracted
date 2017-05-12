#
# Tests the mcast_loopback() method for both IPv4 and IPv6
#

use strict;
use Test::More tests => 9;


# load IO::Socket::Multicast6
BEGIN { use_ok( 'IO::Socket::Multicast6' ); }


# Create an IPv4 multicast socket
my $sock4 = new IO::Socket::Multicast6( Domain => AF_INET );
ok( $sock4, "Create IPv4 multicast socket" );

ok( defined $sock4->mcast_loopback(), "Get loopback state of IPv4 socket" );
ok( defined $sock4->mcast_loopback( 1 ), "Set loopback state of IPv4 socket" );
ok( $sock4->mcast_loopback() == 1, "Verify loopback state of IPv4 socket" );



# Create an IPv6 multicast socket
my $sock6 = new IO::Socket::Multicast6( Domain => AF_INET6 );
ok( $sock6, "Create IPv6 multicast socket" );

ok( defined $sock6->mcast_loopback(), "Get loopback state of IPv6 socket" );
ok( defined $sock6->mcast_loopback( 1 ), "Set loopback state of IPv6 socket" );
ok( $sock6->mcast_loopback() == 1, "Verify loopback state of IPv6 socket" );

