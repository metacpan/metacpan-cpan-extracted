#!/usr/bin/perl
use strict; use warnings;
use Games::AssaultCube::MasterserverQuery;

my $query;
if ( defined $ARGV[0] ) {
	$query = Games::AssaultCube::MasterserverQuery->new( $ARGV[0] );
} else {
	$query = Games::AssaultCube::MasterserverQuery->new;
}

my $response = $query->run;
if ( defined $response ) {
	print "There is a total of " . $response->num_servers . " servers in the list!\n";
} else {
	print "Masterserver at '" . $query->server . "' is not responding!\n";
}
