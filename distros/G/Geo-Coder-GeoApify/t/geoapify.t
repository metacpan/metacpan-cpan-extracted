#!perl -w

use warnings;
use strict;

use Test::Most;
use Test::RequiresInternet('api.geoapify.com' => 'https');	# Must come before T::NoWarnings
use Test::Needs 'Test::Number::Delta';
use Test::NoWarnings;

GEOAPIFY: {
	plan tests => 6;
	use_ok('Geo::Coder::GeoApify');

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

		Test::Number::Delta->import();

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

		delta_within($location->{'features'}[0]{'geometry'}{'coordinates'}[1], 46, 1);	# Latitude
		delta_within($location->{'features'}[0]{'geometry'}{'coordinates'}[0], -65, 1);	# Longitude

		my $address = $geocoder->reverse_geocode(lon => -64.87, lat => 46.67);
		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$address])->Dump());
		}
		like($address->{features}[0]->{'properties'}{'city'}, qr/Richibucto/i, 'test reverse');
	}
}
