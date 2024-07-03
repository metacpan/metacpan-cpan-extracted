#!perl -wT

use strict;
use warnings;
use Test::Most tests => 16;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Location::Point');
}

STRING: {
	my $loc = new_ok('Geo::Location::Point' => [
		lat => 38.9,
		long => -77.04,
		number => 1600,
		street => 'Pennsylvania Ave NW',
		city => 'Washington',
		country => 'US'
	]);

	cmp_ok($loc->as_string(), 'eq', '1600 Pennsylvania Ave NW, Washington, US', 'Test as_string');
	$loc->state('DC');	# Not technically true!
	cmp_ok($loc->number(), '==', 1600, 'House number is 1600');
	is($loc->as_string(), '1600 Pennsylvania Ave NW, Washington, DC, US', 'Test as_string');

	$loc = new_ok('Geo::Location::Point' => [{
		# MaxMind
		'Region' => 'IN',
		'City' => 'new brunswick',
		'Longitude' => '-86.5227778',
		'Country' => 'us',
		'Latitude' => '39.9441667',
		'Population' => '',
		'AccentCity' => 'New Brunswick'
	}]);

	cmp_ok($loc->latitude(), '==', 39.9441667, 'Latitude is set');
	cmp_ok($loc->longitude(), '==', -86.5227778, 'Longitude is set');
	like($loc->as_string(), qr/^New Brunswick/, 'As string includes town');
	like($loc, qr/^New Brunswick/, 'print the object calls as_string');

	$loc = new_ok('Geo::Location::Point' => [
		'Region' => 'Kent',
		'City' => 'Minster',
		'longitude' => 51.34,
		'Country' => 'gb',
		'latitude' => 1.32,
		'AccentCity' => 'Minster',
	]);

	cmp_ok($loc->lat(), '==', 1.32, 'Latitude is set');
	cmp_ok($loc->long(), '==', 51.34, 'Longitude is set');
	is($loc->Country(), 'gb', 'Country is gb');
	like($loc->as_string(), qr/, GB$/, 'GB is put in upper case in as_string');
}
