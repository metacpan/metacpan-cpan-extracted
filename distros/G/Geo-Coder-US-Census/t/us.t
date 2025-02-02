#!perl -w

# TODO:  Add tests and fix
#	7A East 128th Street, Cleveland, Cuyahoga, Ohio, USA
#	131 107th St, Manhattan, New York, New York, USA
#	921 1/2 Sherman Street, Fort Wayne, Allen, Indiana, USA

use warnings;
use strict;
use Data::Dumper;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 18;
use Test::Carp;

BEGIN {
	use_ok('Geo::Coder::US::Census');
}

US: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{AUTHOR_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 17);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 17);
			}
		}

		require_ok('Test::LWP::UserAgent');
		Test::LWP::UserAgent->import();

		my $geocoder = new_ok('Geo::Coder::US::Census');
		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 38.90);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -77.04);	# Long
		sleep(1);

		$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 38.90);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -77.04);	# Long

		# TODO: {
			# Test counties
			# local $TODO = "geocoding.geo.census.gov doesn't support counties";

			if($location = $geocoder->geocode('1363 Kelly Road, Coal City, Owen, Indiana, USA')) {
				if($location->{result}{addressMatches}) {
					# delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 39.27);	# Lat
					# delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -87.03);	# Long
					if($ENV{'TEST_VERBOSE'}) {
						diag(Data::Dumper->new([\$location])->Dump());
					}
					pass('Counties unexpectedly pass Lat');
					pass('Counties unexpectedly pass Long');
				} else {
					fail('Counties Lat');
					fail('Counties Long');
				}
			} else {
				fail('Counties Lat');
				fail('Counties Long');
			}
		# }

		$location = $geocoder->geocode({ location => '6502 SW. 102nd Avenue, Bushnell, Florida, USA' });
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 28.61);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -82.21);	# Long

		$location = $geocoder->geocode('121 McIver Street, Greensboro, Guilford, North Carolina');
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 36.08);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -79.81);	# Long
		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$location])->Dump());
		}

		$location = $geocoder->geocode('105 S. West Street, Spencer, Owen, Indiana');
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{y}, 39.28);	# Lat
		delta_ok($location->{result}{addressMatches}[0]->{coordinates}{x}, -86.76);	# Long
		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$location])->Dump());
		}

		# my $address = $geocoder->reverse_geocode('38.9,-77.04');
		# is($address->{'prov'}, 'DC', 'test reverse');

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocoding.geo.census.gov', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);

		sub f {
			$location = $geocoder->geocode({ location => '1600 Pennsylvania Avenue NW, Washington DC, USA' });
		}
		does_carp_that_matches(\&f, qr/https?:\/\/geocoding.geo.census.gov.+ API returned error: 500/);
	}
}
