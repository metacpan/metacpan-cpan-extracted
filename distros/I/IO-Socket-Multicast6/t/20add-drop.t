#
# Try join/leaving IPv4 and IPv6 muticast groups
#

use strict;
use Test::More tests => 7;


# load IO::Socket::Multicast6
BEGIN { use_ok( 'IO::Socket::Multicast6' ); }


# Create an IPv4 multicast socket
my $sock4 = new IO::Socket::Multicast6( Domain => AF_INET );
ok( $sock4, "Create IPv4 multicast socket" );

is( $sock4->mcast_add('239.255.1.1'), 1, "Join IPv4 multicast group" );
is( $sock4->mcast_drop('239.255.1.1'), 1, "Drop IPv4 multicast group" );



# Create an IPv6 multicast socket
my $sock6 = new IO::Socket::Multicast6( Domain => AF_INET6 );
ok( $sock6, "Create IPv6 multicast socket" );

is( $sock6->mcast_add('FF11::11'), 1, "Join IPv6 multicast group" );
is( $sock6->mcast_drop('FF11::11'), 1, "Drop IPv6 multicast group" );
