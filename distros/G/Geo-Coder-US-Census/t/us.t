#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 9;
use Test::Carp;

BEGIN {
	use_ok('Geo::Coder::US::Census');
}

US: {
	SKIP: {
		skip 'Test requires Internet access', 8 unless(-e 't/online.enabled');

		require Test::LWP::UserAgent;
		Test::LWP::UserAgent->import();

		my $geocoder = new_ok('Geo::Coder::US::Census');
		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 38.90);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -77.04);	# Long
		sleep(1);

		$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 38.90);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -77.04);	# Long

		# my $address = $geocoder->reverse_geocode('38.9,-77.04');
		# is($address->{'prov'}, 'DC', 'test reverse');

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocoding.geo.census.gov', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);

		sub f {
			$location = $geocoder->geocode({ location => '1600 Pennsylvania Avenue NW, Washington DC, USA' });
		};
		does_croak_that_matches(\&f, qr/^geocoding.geo.census.gov API returned error: 500/);
	}
}
