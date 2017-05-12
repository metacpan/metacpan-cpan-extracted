#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';
use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use HTTP::Client::Parallel qw{ mirror get };

my $client = HTTP::Client::Parallel->new;
isa_ok( $client, 'HTTP::Client::Parallel' );

# get
if ( 0 ) {
	my $responses = $client->get(
		'http://www.google.com',
		'http://www.yapc.org',
		'http://www.yahoo.com',
	);

	warn Dumper( $responses );
}

# Regular fetching via the object
SCOPE: {
	my $responses = $client->get(
		'http://www.google.com/',
	);
	is( ref($responses), 'ARRAY', 'Got an array ref' );
	is( scalar(@$responses), 1, 'Got a single element' );
	isa_ok( $responses->[0], 'HTTP::Response' );
}

# Shorthand version
SCOPE: {
	my $responses = get(
		'http://www.google.com/',
	);
	is( ref($responses), 'ARRAY', 'Got an array ref' );
	is( scalar(@$responses), 1, 'Got a single element' );
	isa_ok( $responses->[0], 'HTTP::Response' );
}
