#
# Try and send some multicast packets on IPv4 and IPv6 
#

use strict;
use Test::More tests => 5;


# load IO::Socket::Multicast6
BEGIN { use_ok( 'IO::Socket::Multicast6' ); }


# Create an IPv4 multicast socket
my $sock4 = new IO::Socket::Multicast6(
						PeerAddr => '239.255.30.29',
						PeerPort => 2000,
						Domain => AF_INET,
						ReuseAddr=>1);
ok( $sock4, "Create IPv4 multicast socket" );

is($sock4->send( 'Hello World!'), 12, "Sent 12 bytes on IPv4 socket." );



# Create an IPv6 multicast socket
my $sock6 = new IO::Socket::Multicast6(
						PeerAddr => 'ff15::5042',
						PeerPort => 2000,
						Domain => AF_INET6,
						ReuseAddr=>1);
ok( $sock6, "Create IPv6 multicast socket" );

is($sock6->send( 'Hello World!'), 12, "Sent 12 bytes on IPv6 socket." );
