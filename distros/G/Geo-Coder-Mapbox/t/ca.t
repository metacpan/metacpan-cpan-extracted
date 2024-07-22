#!perl -w

use warnings;
use strict;
use Test::Most tests => 7;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::Mapbox');
}

CA: {
	SKIP: {
		if(!-e 't/online.enabled') {
			diag('Online tests disabled');
			skip('Test requires Internet access', 5);
		}
		my $access_token = $ENV{'MAPBOX_KEY'};
		if((!defined($access_token)) || (length($access_token) == 0)) {
			diag('Set MAPBOX_KEY variable to your API key');
			skip('Set MAPBOX_KEY variable to your API key', 5);
		}

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip('Test::Number::Delta not installed', 5);
		}

		my $ua;

		eval {
			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();

			$ua = LWP::UserAgent::Throttled->new();
			$ua->throttle({ 'api.mapbox.com' => 2 });
			$ua->env_proxy(1);
		};

		my $geocoder = new_ok('Geo::Coder::Mapbox' => [ 'access_token' => $access_token ]);

		if($ua) {
			$geocoder->ua($ua);
		}

		my $location = $geocoder->geocode('Richibucto, New Brunswick, Canada');
		# diag(Data::Dumper->new([$location])->Dump());

		delta_within($location->{features}[0]->{center}[1], 46.7, 1e-1);	# Latitude
		delta_within($location->{features}[0]->{center}[0], -64.9, 1e-1);	# Longitude

		my $address = $geocoder->reverse_geocode(lnglat => '-64.87,46.67');
		# diag(Data::Dumper->new([$address])->Dump());
		like($address->{features}[0]->{place_name}, qr/Richibucto/i, 'test reverse');

		$address = $geocoder->reverse_geocode('-64.87,46.67');
		like($address->{features}[0]->{place_name}, qr/Richibucto/i, 'test reverse, lnglat implied');
	}
}
