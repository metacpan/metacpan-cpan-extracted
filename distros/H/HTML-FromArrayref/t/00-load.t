#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::FromArrayref' ) || print "Bail out!\n";
}

diag( "Testing HTML::FromArrayref $HTML::FromArrayref::VERSION, Perl $], $^X" );
