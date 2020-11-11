#!perl -wT

use strict;
use warnings;
use Test::Most tests => 8;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Location::Point');
}

DISTANCE: {
	my $loc = new_ok('Geo::Location::Point' => [
		lat => 38.9,
		long => -77.04,
		number => 1600,
		street => 'Pennsylvania Ave NW',
		city => 'Washington',
		country => 'US'
	]);

	$loc->state('DC');	# Not technically true!
	ok($loc->number() == 1600);
	ok($loc->as_string() eq '1600 Pennsylvania Ave NW, Washington, DC, US');

	$loc = new_ok('Geo::Location::Point' => [
		# MaxMind
		'Region' => 'IN',
		'City' => 'new brunswick',
		'Longitude' => '-86.5227778',
		'Country' => 'us',
		'Latitude' => '39.9441667',
		'Population' => '',
		'AccentCity' => 'New Brunswick'
	]);

	ok($loc->as_string() =~ /New Brunswick/);
	ok($loc =~ /New Brunswick/);
}
