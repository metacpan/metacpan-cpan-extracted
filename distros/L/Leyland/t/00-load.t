#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Leyland' ) || print "Leyland bail out!\n";
}

diag( "Testing Leyland $Leyland::VERSION, Perl $], $^X" );
