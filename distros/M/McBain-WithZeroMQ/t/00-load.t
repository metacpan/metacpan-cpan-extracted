#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'McBain::WithZeroMQ' ) || print "Bail out!\n";
}

diag( "Testing McBain::WithZeroMQ $McBain::WithZeroMQ::VERSION, Perl $], $^X" );
