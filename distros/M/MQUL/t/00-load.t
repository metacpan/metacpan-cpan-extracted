#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'MQUL' ) || print "Bail out!\n";
}

diag( "Testing MQUL $MQUL::VERSION, Perl $], $^X" );
