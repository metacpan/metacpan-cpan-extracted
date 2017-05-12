#!/usr/bin/perl
use strict; use warnings;
use Games::AssaultCube::ServerQuery;

if ( defined $ARGV[0] ) {
	my $query;
	if ( defined $ARGV[1] ) {
		$query = Games::AssaultCube::ServerQuery->new({ server => $ARGV[0], port => $ARGV[1], timeout => 2 });
	} else {
		$query = Games::AssaultCube::ServerQuery->new( $ARGV[0] );
	}

	my $response = $query->run;
	if ( defined $response ) {
		print "Server '" . $response->desc_nocolor . "' is running with " . $response->players . " players on map " .
		$response->map . " on mode(" . $response->gamemode_name . ")\n";
		print "datagram length: " . length( $response->datagram ) . "\n";
	} else {
		print "Server is not responding!\n";
	}
} else {
	print "Please supply a server ip to query [ optionally with port ]\n";
}
