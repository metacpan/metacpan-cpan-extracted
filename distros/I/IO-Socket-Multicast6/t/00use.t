use strict;
use Test::More tests => 3;


# Check that the module loads ok
BEGIN { use_ok( 'IO::Socket::Multicast6' ); }


# Now try creating a new IO::Socket::Multicast6 socket
my $sock = new IO::Socket::Multicast6();
ok( $sock, "Creating IO::Socket::Multicast6 object" );


# Close the socket
$sock->close();
pass( "Closing socket" );
