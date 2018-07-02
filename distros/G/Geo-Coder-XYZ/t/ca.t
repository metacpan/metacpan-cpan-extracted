#!perl -w

use warnings;
use strict;
use Test::Most tests => 9;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::XYZ');
}

CA: {
	SKIP: {
		if(!-e 't/online.enabled') {
			diag('Online tests disabled');
			skip 'Test requires Internet access', 7;
		}

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip 'Test::Number::Delta not installed', 7;
		}

		my $geocoder = new_ok('Geo::Coder::XYZ');
		my $location = $geocoder->geocode('9235 Main St, Richibucto, New Brunswick, Canada');
		delta_within($location->{latt}, 43.74, 1e-2);
		delta_within($location->{longt}, -80.96, 1e-2);

		$location = $geocoder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
		delta_within($location->{latt}, 43.74, 1e-2);
		delta_within($location->{longt}, -80.96, 1e-2);

		my $address = $geocoder->reverse_geocode(latlng => '46.67,-64.87');
		like($address->{'city'}, qr/Richibucto/i, 'test reverse');

		$address = $geocoder->reverse_geocode('46.67,-64.87');
		like($address->{'city'}, qr/Richibucto/i, 'test reverse, latng implied');
	}
}
