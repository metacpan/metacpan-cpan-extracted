#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 5;
use Geo::Location::Point;

CARP: {
	does_carp_that_matches(sub {
		ok(!defined(Geo::Location::Point->new()))
	}, qr/latitude not given/);

	does_carp_that_matches(sub {
		ok(!defined(Geo::Location::Point->new(lat => 0)))
	}, qr/longitude not given/);

	ok(defined(Geo::Location::Point->new(lat => 0, long => 0)));
}
