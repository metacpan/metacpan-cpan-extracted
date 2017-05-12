#!perl -T

use Test::More tests => 12;

BEGIN {
	use_ok( 'Geo::Coder::GoogleMaps' );
}

diag("\nWARNING:\nThe following tests requires two thing :\n1) to be connected to the internet\n2) to have a valid Google API key exported as GAPI_KEY.\nIf you don't have those the test will be skip.\n");

SKIP: {
	skip( "Real tests are skipped because you haven't defined the GAPI_KEY environnement variable.", 11 ) if(!defined($ENV{GAPI_KEY}));
	my $gmap = Geo::Coder::GoogleMaps->new( apikey => $ENV{GAPI_KEY} , output => 'xml');
	ok(defined($gmap));
	ok( $gmap->isa('Geo::Coder::GoogleMaps') );
	my $response = $gmap->geocode('88, Rue du Château, 92600 Asnières-sur-Seine, France');
	ok(defined($response));
	ok( $response->isa('Geo::Coder::GoogleMaps::Response') );
	ok( $response->is_success() );
	my $loc = $response->placemarks()->[0];
	ok(defined($loc));
	ok( $loc->isa('Geo::Coder::GoogleMaps::Location') );
	
	ok( $loc->SubAdministrativeAreaName eq 'Hauts-de-Seine' );
	ok( $loc->PostalCodeNumber eq '92600' );
	ok( $loc->AdministrativeAreaName eq 'Ile-de-France' );
	ok( $loc->CountryNameCode eq 'FR' );
}
