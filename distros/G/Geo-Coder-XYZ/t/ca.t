#!perl -w

use warnings;
use strict;
use Test::Most 'no_plan';
use Test::Needs 'LWP::UserAgent::Throttled', 'Test::Number::Delta';
use Test::NoWarnings;

BEGIN { use_ok('Geo::Coder::XYZ') }

CA: {
	SKIP: {
		if(!-e 't/online.enabled') {
			diag('Online tests disabled');
			skip('Test requires Internet access', 8);
		}

		Test::Number::Delta->import();

		my $ua = new_ok('LWP::UserAgent::Throttled');
		$ua->throttle({ 'geocode.xyz' => 3 });
		$ua->env_proxy(1);

		my $geocoder = new_ok('Geo::Coder::XYZ');

		$geocoder->ua($ua);

		my $location = $geocoder->geocode('9235 Main St, Richibucto, New Brunswick, Canada');
		delta_within($location->{latt}, 46.7, 1e-1);
		delta_within($location->{longt}, -64.9, 1e-1);

		$location = $geocoder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
		delta_within($location->{latt}, 46.7, 1e-1);
		delta_within($location->{longt}, -64.9, 1e-1);

		my $address = $geocoder->reverse_geocode(latlng => '46.67,-64.87');
		like($address->{'city'}, qr/Richibucto/i, 'test reverse');

		$address = $geocoder->reverse_geocode('46.67,-64.87');
		like($address->{'city'}, qr/Richibucto/i, 'test reverse, latng implied');
	}
}
