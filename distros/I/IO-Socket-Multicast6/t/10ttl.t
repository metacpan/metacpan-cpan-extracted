#
# Tests the mcast_ttl() method for both IPv4 and IPv6
#

use Test::More tests => 9;
use strict;


# load IO::Socket::Multicast6
BEGIN { use_ok( 'IO::Socket::Multicast6' ); }


# Create an IPv4 multicast socket
my $sock4 = new IO::Socket::Multicast6( Domain => AF_INET );
ok( $sock4, "Create IPv4 multicast socket" );

ok( $sock4->mcast_ttl(), "Get TTL value of IPv4 socket" );
ok( $sock4->mcast_ttl( 6 ), "Set TTL value of IPv4 socket" );
ok( $sock4->mcast_ttl() == 6, "Verify TTL value of IPv4 socket" );



# Create an IPv6 multicast socket
my $sock6 = new IO::Socket::Multicast6( Domain => AF_INET6 );
ok( $sock6 );

ok( $sock6->mcast_ttl(), "Get TTL value of IPv6 socket" );
ok( $sock6->mcast_ttl( 6 ), "Set TTL value of IPv6 socket" );
ok( $sock6->mcast_ttl() == 6, "Verify TTL value of IPv6 socket" );

