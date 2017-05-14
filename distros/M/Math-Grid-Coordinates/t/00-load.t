#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::Grid::Coordinates' );
}

diag( "Testing Math::Grid::Coordinates, Perl $], $^X" );
