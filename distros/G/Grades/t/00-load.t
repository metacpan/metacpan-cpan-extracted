#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Grades' );
}

diag( "Testing Grades $Grades::VERSION, Perl $], $^X" );
