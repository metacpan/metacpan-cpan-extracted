#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Geo::Coder::GoogleMaps' );
}

diag( "Testing Geo::Coder::GoogleMaps $Geo::Coder::GoogleMaps::VERSION, Perl $], $^X" );
