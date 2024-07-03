#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 10;
use Geo::Location::Point;

CARP: {
	does_carp_that_matches(sub {
		ok(!defined(Geo::Location::Point->new()))
	}, qr/latitude not given/);

	does_carp_that_matches(sub {
		ok(!defined(Geo::Location::Point->new(lat => 0)))
	}, qr/longitude not given/);

	does_carp_that_matches(sub {
		ok(!defined(Geo::Location::Point->new(lat => 0, long => 181)))
	}, qr/invalid longitude/);

	does_carp_that_matches(sub {
		ok(!defined(Geo::Location::Point->new(lat => -182, long => 0)))
	}, qr/invalid latitude/);

	my $point = new_ok('Geo::Location::Point' => [
		lat => 0, long => 0
	]);

	does_carp_that_matches(sub {
		$point->distance()
	}, qr/Usage/);
}
