#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 13;
use Test::Carp;

BEGIN {
	use_ok('Geo::Coder::US::Census');
}

US: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{AUTHOR_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 12);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 12);
			}
		}

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

		TODO: {
			# Test counties
			local $TODO = "geocoding.geo.census.gov doesn't support counties";

			$location = $geocoder->geocode('1363 Kelly Road, Coal City, Owen, Indiana, USA');
			delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 39.27);	# Lat
			delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -87.03);	# Long
		}

		$location = $geocoder->geocode({ location => '6502 SW. 102nd Avenue, Bushnell, Florida, USA' });
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 28.61);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -82.21);	# Long

		# my $address = $geocoder->reverse_geocode('38.9,-77.04');
		# is($address->{'prov'}, 'DC', 'test reverse');

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocoding.geo.census.gov', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);

		sub f {
			$location = $geocoder->geocode({ location => '1600 Pennsylvania Avenue NW, Washington DC, USA' });
		}
		does_croak_that_matches(\&f, qr/https?:\/\/geocoding.geo.census.gov.+ API returned error: 500/);
	}
}
