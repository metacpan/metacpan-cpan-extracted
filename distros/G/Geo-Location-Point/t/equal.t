#!perl -wT

use strict;
use warnings;
use Test::Most tests => 11;
use Test::NoWarnings;
use Test::Number::Delta;

BEGIN {
	use_ok('Geo::Location::Point');
}

DISTANCE: {
	my $loc1 = new_ok('Geo::Location::Point' => [
		Latitude => 51.34203083,
		long => 1.31609075,
		county => 'Kent',
		country => 'GB'
	]);
	my $loc2 = new_ok('Geo::Location::Point' => [
		Latitude => 51.34203083,
		long => 1.31609075,
		county => 'Kent',
		country => 'GB'
	]);
	my $loc3 = new_ok('Geo::Location::Point' => [
		lat => 51.34015944,
		Longitude => 1.31580976,
		county => 'Kent',
		country => 'GB'
	]);

	ok($loc1 == $loc2);
	ok($loc1 == $loc1);
	ok($loc1 != $loc3);
	ok($loc1->equals($loc2));
	ok($loc3 != $loc2);
	ok($loc3->not_equal($loc2));
}
