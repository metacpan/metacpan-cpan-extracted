#!perl -T

use Test::More tests => 17;

BEGIN {
	use_ok( 'Geo::Coder::GoogleMaps::Location' );
}

my $loc = Geo::Coder::GoogleMaps::Location->new();
ok(defined $loc);
ok($loc->isa('Geo::Coder::GoogleMaps::Location'));

ok($loc->SubAdministrativeAreaName('Hauts-de-Seine'));
ok( $loc->SubAdministrativeAreaName eq 'Hauts-de-Seine' );

ok( $loc->PostalCodeNumber('92600') );
ok( $loc->PostalCodeNumber eq '92600' );

ok( $loc->LocalityName('Asnières-sur-Seine') );
ok( $loc->LocalityName eq 'Asnières-sur-Seine' );

ok( $loc->ThoroughfareName('88, Rue du Château') );
ok( $loc->ThoroughfareName eq '88, Rue du Château' );

ok( $loc->AdministrativeAreaName('Ile-de-France') );
ok( $loc->AdministrativeAreaName eq 'Ile-de-France' );

ok( $loc->CountryNameCode('FR') );
ok( $loc->CountryNameCode eq 'FR' );

ok( $loc->address('88, Rue du Château, 92600 Asnières-sur-Seine, France') );
ok( $loc->address eq '88, Rue du Château, 92600 Asnières-sur-Seine, France' );
