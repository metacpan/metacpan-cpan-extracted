#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 7;

BEGIN {
	use_ok('Geo::Coder::XYZ');
}

UK: {
	SKIP: {
		skip 'Test requires Internet access', 6 unless(-e 't/online.enabled');

		my $geocoder = new_ok('Geo::Coder::XYZ');

		my $location = $geocoder->geocode('10 Downing St., London, UK');
		delta_ok($location->{latt}, 51.50);
		delta_ok($location->{longt}, -0.13);

		$location = $geocoder->geocode(location => '10 Downing St., London, UK');
		delta_ok($location->{latt}, 51.50);
		delta_ok($location->{longt}, -0.13);

		my $address = $geocoder->reverse_geocode(latlng => '51.50,-0.13');
		like($address->{'city'}, qr/^London$/i, 'test reverse');
	}
}
