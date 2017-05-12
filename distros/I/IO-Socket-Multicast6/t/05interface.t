#
# Try attaching to a multicast interface
#

use strict;
use Test::More tests => 10;


# load IO::Socket::Multicast6 and IO::Interface
BEGIN {
	use_ok( 'IO::Interface::Simple' );
	use_ok( 'IO::Socket::Multicast6' );
}


# Find first multicast enabled interface
my $iface = undef;
my @interfaces = IO::Interface::Simple->interfaces;
foreach my $if (@interfaces) {
	next unless ($if->is_running);
	next unless ($if->is_multicast);
	
	# Found multicast enabled interface
	$iface = $if->name();
	last;
}

unless (defined $iface) {
	die( "Failed to find multicast enabled interface." );
}


# Create an IPv4 multicast socket
my $sock4 = new IO::Socket::Multicast6( Domain => AF_INET );
ok( $sock4, "Create IPv4 multicast socket" );

ok( defined $sock4->mcast_if(), "Get outgoing interface of IPv4 socket" );
ok( defined $sock4->mcast_if($iface), "Set outgoing interface of IPv4 socket" );
ok( $sock4->mcast_if() eq $iface, "Verify outgoing interface of IPv4 socket" );


# Create an IPv6 multicast socket
my $sock6 = new IO::Socket::Multicast6( Domain => AF_INET6 );
ok( $sock6, "Create IPv6 multicast socket" );

ok( defined $sock6->mcast_if(), "Get outgoing interface of IPv6 socket" );
ok( defined $sock6->mcast_if($iface), "Set outgoing interface of IPv6 socket" );
ok( $sock6->mcast_if() eq $iface, "Verify outgoing interface of IPv6 socket" );

