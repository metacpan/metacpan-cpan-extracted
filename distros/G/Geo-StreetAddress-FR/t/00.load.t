use Test::More tests => 3;

BEGIN {
use_ok( 'Geo::StreetAddress::FR' );
}

diag( "Testing Geo::StreetAddress::FR $Geo::StreetAddress::FR::VERSION" );

can_ok('Geo::StreetAddress::FR', 'parse');
can_ok('Geo::StreetAddress::FR', '_adress_missing');