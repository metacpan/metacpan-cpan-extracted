#
# Try and send some multicast packets on IPv4 and IPv6, multicast API style
#

use strict;
use Socket6 qw/ inet_pton pack_sockaddr_in6/;
use Socket qw/  pack_sockaddr_in /;
use Test::More tests => 11;


# load IO::Socket::Multicast6
BEGIN { use_ok( 'IO::Socket::Multicast6' ); }


# Create an IPv4 multicast socket
my $sock4 = new IO::Socket::Multicast6( Domain => AF_INET );
ok( $sock4, "Create IPv4 multicast socket" );


$sock4->mcast_dest( '239.255.30.29:2000' );
ok( defined $sock4->mcast_dest(), "Combined IPv4 destination address and port" );

$sock4->mcast_dest( '239.255.30.29', 2000 );
ok( defined $sock4->mcast_dest(), "Separate IPv4 destination address and port" );

$sock4->mcast_dest( pack_sockaddr_in(2000,inet_pton(AF_INET, '239.255.30.29')) );
ok( defined $sock4->mcast_dest(), "Packed IPv4 destination address and port" );

is($sock4->mcast_send( 'Hello World!' ), 12, "Sent 12 bytes on IPv4 socket." );



# Create an IPv6 multicast socket
my $sock6 = new IO::Socket::Multicast6( Domain => AF_INET6 );
ok( $sock6, "Create IPv6 multicast socket" );

$sock6->mcast_dest( '[ff15::5042]:2000' );
ok( defined $sock6->mcast_dest(), "Combined IPv6 destination address and port" );

$sock6->mcast_dest( 'ff15::5042', 2000 );
ok( defined $sock6->mcast_dest(), "Separate IPv6 destination address and port" );

$sock6->mcast_dest( pack_sockaddr_in6(2000,inet_pton(AF_INET6, 'ff15::5042')) );
ok( defined $sock6->mcast_dest(), "Packed IPv6 destination address and port" );

is($sock6->mcast_send( 'Hello World!' ), 12, "Sent 12 bytes on IPv6 socket." );
