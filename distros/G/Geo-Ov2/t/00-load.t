#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Geo::Ov2' );
}

diag( "Testing Geo::Ov2 $Geo::Ov2::VERSION, Perl $], $^X" );
