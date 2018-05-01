#!perl -w

use warnings;
use strict;
use Test::Most tests => 14;

BEGIN {
	use_ok('Geo::Coder::XYZ');
}

UK: {
	SKIP: {
		skip 'Test requires Internet access', 13 unless(-e 't/online.enabled');

		require Test::LWP::UserAgent;
		Test::LWP::UserAgent->import();

		require Test::Carp;
		Test::Carp->import();

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip 'Test::Number::Delta not installed', 13;
		}

		my $geocoder = new_ok('Geo::Coder::XYZ');

		my $location = $geocoder->geocode('Ramsgate, Kent, England');
		delta_within($location->{latt}, 51.34, 1e-2);
		delta_within($location->{longt}, 1.39, 1e-2);

		$location = $geocoder->geocode('10 Downing St., London, UK');
		delta_within($location->{latt}, 51.50, 1e-2);
		delta_within($location->{longt}, -0.13, 1e-2);

		$location = $geocoder->geocode('Wokingham, Berkshire, England');
		delta_within($location->{latt}, 51.42, 1e-2);
		delta_within($location->{longt}, -0.84, 1e-2);

		$location = $geocoder->geocode(location => '10 Downing St., London, UK');
		delta_within($location->{latt}, 51.50, 1e-2);
		delta_within($location->{longt}, -0.13, 1e-2);

		my $address = $geocoder->reverse_geocode(latlng => '51.50,-0.13');
		like($address->{'city'}, qr/(City of Westminster|LONDON)/, 'test reverse');

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocode.xyz', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);
		does_carp_that_matches(sub {
			$location = $geocoder->geocode('10 Downing St., London, UK');
		}, qr/^API returned error: on.+500/);
	}
}
