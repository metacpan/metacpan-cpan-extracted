#!perl -T

use Test::More tests => 10;

BEGIN {
	use_ok( 'Geo::Coder::GoogleMaps::Location' );
}

my $loc = Geo::Coder::GoogleMaps::Location->new();
ok(defined $loc);
ok($loc->isa('Geo::Coder::GoogleMaps::Location'));
ok( $loc->SubAdministrativeAreaName eq '' );
ok( $loc->PostalCodeNumber eq '' );
ok( $loc->LocalityName eq '' );
ok( $loc->ThoroughfareName eq '' );
ok( $loc->AdministrativeAreaName eq '' );
ok( $loc->CountryNameCode eq '' );
ok( $loc->address eq '' );
