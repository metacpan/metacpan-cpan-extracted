#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most tests => 6;

BEGIN { use_ok('Geo::Location::Point') }

# Test 'new' constructor
subtest 'Constructor tests' => sub {
	my $point = Geo::Location::Point->new({ latitude => 10, longitude => 20 });
	ok($point, 'Point object created');
	is($point->lat(), 10, 'Latitude is correct');
	is($point->long(), 20, 'Longitude is correct');

	# Invalid latitude
	my $invalid_latitude = Geo::Location::Point->new({ latitude => 200, longitude => 20 });
	ok(!$invalid_latitude, 'Invalid latitude detected');

	# Invalid longitude
	my $invalid_longitude = Geo::Location::Point->new({ latitude => 10, longitude => 200 });
	ok(!$invalid_longitude, 'Invalid longitude detected');
};

# Test 'equal' and 'not_equal' methods
subtest 'Equality tests' => sub {
	my $point1 = Geo::Location::Point->new({ latitude => 10, longitude => 20 });
	my $point2 = Geo::Location::Point->new(latitude => 10, longitude => 20);
	my $point3 = Geo::Location::Point->new({ latitude => 15, longitude => 25 });

	ok($point1 == $point2, 'Points are equal');
	ok($point1 != $point3, 'Points are not equal');
};

# Test 'as_string' method
subtest 'String representation tests' => sub {
	my $point = Geo::Location::Point->new({
		latitude => 10,
		longitude => 20,
		city => 'TestCity',
		country => 'US'
	});

	like($point->as_string(), qr/Testcity, US/, 'String representation includes city and country');
};

# Test distance calculation
subtest 'Distance tests' => sub {
	my $point1 = Geo::Location::Point->new({ latitude => 10, longitude => 20 });
	my $point2 = Geo::Location::Point->new({ latitude => 15, longitude => 25 });

	my $distance = $point1->distance($point2);
	cmp_ok($distance->value(), '>', 0, 'Distance is positive');
};

# Test 'as_uri' method
subtest 'URI representation tests' => sub {
	my $point = Geo::Location::Point->new(latitude => 10, longitude => 20);
	is($point->as_uri(), 'geo:10,20', 'URI representation is correct');
};
