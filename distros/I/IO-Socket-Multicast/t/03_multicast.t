#!/usr/bin/perl
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use IO::Socket::Multicast;

my $MCAST_ADDR = '225.0.0.1';
my $MCAST_PORT = 9999;

# I think winsock prefers the socket
#  to be bound to _something_
my $s = IO::Socket::Multicast->new(
    LocalPort => $MCAST_PORT,
);

# Platform compatibility
my $WIN32        = $^O eq 'MSWin32';
my $LINUX        = $WIN32 ? 0 : (`uname -sr` =~ /^Linux (\d+\.\d+)/)[0];
my $OS_OK        = ( $LINUX and $LINUX >= 2.2 );
my $IO_INTERFACE = eval "use IO::Interface ':flags'; 1;";
my $INTERFACE    = $IO_INTERFACE && find_a_mcast_if($s);


SKIP: {
	# run only if there is an interface
	skip("There is no interface, so we can't check", 3) unless $INTERFACE;
	isa_ok( $s, 'IO::Socket::Multicast' );
	ok($s->mcast_add($MCAST_ADDR), 'Add socket to Multicast Group' );
	ok($s->mcast_drop($MCAST_ADDR),'Drop Multicast Group' );
}
	
# Some basics
SKIP: {
	# Windows doesn't return true for stuff
	skip("Doesn't work on Win32??", 1) if $WIN32;
	ok( ! $s->mcast_drop($MCAST_ADDR), 'Drop unsubscribed group returns false' );
}

# More subtle control
SKIP: {
	skip("Needs Linux >= 2.2", 6) unless $OS_OK;
	ok($s->mcast_ttl         == 1,  'Get socket TTL default is one');
	ok($s->mcast_ttl(10)     == 1,  'Set TTL returns previous value');
	ok($s->mcast_ttl         == 10, 'Get TTL post-set returns correct TTL');
	ok($s->mcast_loopback    == 1,  'Multicast loopback defaults to true');
	ok($s->mcast_loopback(0) == 1,  'Loopback set returns previous value' );
	ok($s->mcast_loopback    == 0,  'Loopback get' );
}

SKIP: {
	skip('IO::Interface not available', 4)      unless $IO_INTERFACE;
	skip('No multicast interface available', 4) unless $INTERFACE;
	skip('Needs Linux >= 2.2', 4)               unless $OS_OK;
	ok ($s->mcast_if  eq 'any' ,    'Default interface "any"');
	ok ($s->mcast_if($INTERFACE) eq 'any', 'Multicast interface set returns previous value');
	ok ($s->mcast_if eq $INTERFACE , 'Multicast interface set');
	ok ($s->mcast_add($MCAST_ADDR,$INTERFACE), 'Multicast add GROUP,if');
}

sub find_a_mcast_if {
	my $s   = shift;
	my @ifs = $s->if_list;
	foreach ( reverse @ifs ) {
		next unless $s->if_flags($_) & IFF_MULTICAST();
		next unless $s->if_flags($_) & IFF_RUNNING();
		next unless $s->if_addr($_); # Having an address seems important
		return $_;
	}
}
