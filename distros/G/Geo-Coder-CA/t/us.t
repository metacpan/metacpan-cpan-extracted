#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 7;

BEGIN {
	use_ok('Geo::Coder::CA');
}

US: {
	SKIP: {
		skip 'Test requires Internet access', 6 unless(-e 't/online.enabled');

		my $geocoder = new_ok('Geo::Coder::CA');
		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		delta_ok($location->{latt}, 38.90);
		delta_ok($location->{longt}, -77.04);

		$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
		delta_ok($location->{latt}, 38.90);
		delta_ok($location->{longt}, -77.04);

		my $address = $geocoder->reverse_geocode(latlng => '38.9,-77.04');
		is($address->{'prov'}, 'DC', 'test reverse');
	}
}
