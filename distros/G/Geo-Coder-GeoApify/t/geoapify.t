#!perl -w

use warnings;
use strict;
use Test::Most tests => 6;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::GeoApify');
}

GEOAPIFY: {
	SKIP: {
		if(!-e 't/online.enabled') {
			diag('Online tests disabled');
			skip('Test requires Internet access', 4);
		}

		my $apiKey = $ENV{'GEOAPIFY_KEY'};
		if((!defined($apiKey)) || (length($apiKey) == 0)) {
			diag('Set GEOAPIFY_KEY variable to your API key');
			skip('Set GEOAPIFY_KEY variable to your API key', 4);
		}

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip('Test::Number::Delta not installed', 4);
		}

		my $ua;

		eval {
			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();

			$ua = LWP::UserAgent::Throttled->new();
			$ua->throttle({ 'api.geoapify.com' => 2 });
			$ua->env_proxy(1);
		};

		my $geocoder = new_ok('Geo::Coder::GeoApify' => [ 'apiKey' => $apiKey ]);

		if($ua) {
			$geocoder->ua($ua);
		}

		my $location = $geocoder->geocode('Richibucto, New Brunswick, Canada');
		# diag(Data::Dumper->new([$location])->Dump());

		delta_within($location->{'features'}[0]{'geometry'}{'coordinates'}[1], 46.5, 1e-1);	# Latitude
		delta_within($location->{'features'}[0]{'geometry'}{'coordinates'}[0], -65.4, 1e-1);	# Longitude

		my $address = $geocoder->reverse_geocode(lon => -64.87, lat => 46.67);
		# diag(Data::Dumper->new([$address])->Dump());
		like($address->{features}[0]->{'properties'}{'city'}, qr/Richibucto/i, 'test reverse');
	}
}
