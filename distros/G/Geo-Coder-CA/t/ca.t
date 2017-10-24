#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 7;

BEGIN {
	use_ok('Geo::Coder::CA');
}

CA: {
	SKIP: {
		skip 'Test requires Internet access', 6 unless(-e 't/online.enabled');

		my $geocoder = new_ok('Geo::Coder::CA');
		my $location = $geocoder->geocode('9235 Main St, Richibucto, New Brunswick, Canada');
		delta_ok($location->{latt}, 46.67);
		delta_ok($location->{longt}, -64.87);

		$location = $geocoder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
		delta_ok($location->{latt}, 46.67);
		delta_ok($location->{longt}, -64.87);

		my $address = $geocoder->reverse_geocode(latlng => '46.67,-64.87');
		like($address->{'city'}, qr/Richibucto/i, 'test reverse city');
		# like($address->{'country'}, qr/Canada/i, 'test reverse country');

		# This gives invalid JSON. It has been reported to geocoder.ca.
		# $location = $geocoder->geocode('Nassagaweya, Halton, Ontario, Canada');
	}
}
