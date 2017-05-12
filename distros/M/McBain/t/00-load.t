#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'McBain' ) || print "Bail out!\n";
}

diag( "Testing McBain $McBain::VERSION, Perl $], $^X" );
