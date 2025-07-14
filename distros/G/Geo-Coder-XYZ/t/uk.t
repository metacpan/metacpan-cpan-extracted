#!perl -w

use warnings;
use strict;
use Test::Most tests => 15;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::XYZ');
}

UK: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{AUTHOR_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 13);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 13);
			}
		}

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

		my $ua;

		eval {
			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttle->import;

			$ua = LWP::UserAgent::Throttled->new();
			$ua->throttle({ 'geocode.xyz' => 2 });
			$ua->env_proxy(1);
		};

		my $geocoder = new_ok('Geo::Coder::XYZ');

		if($ua) {
			$geocoder->ua($ua);
		}

		my $location = $geocoder->geocode('Ramsgate, Kent, England');
		delta_within($location->{latt}, 51.3, 1e-1);
		delta_within($location->{longt}, 1.4, 1e-1);

		$location = $geocoder->geocode({ location => '10 Downing St., London, UK' });
		delta_within($location->{latt}, 51.5, 1e-1);
		delta_within($location->{longt}, -0.1, 1e-1);

		$location = $geocoder->geocode(location => 'Wokingham, Berkshire, England');
		delta_within($location->{latt}, 51.4, 1e-1);
		delta_within($location->{longt}, -0.8, 1e-1);

		$location = $geocoder->geocode(location => '10 Downing St., London, UK');
		delta_within($location->{latt}, 51.5, 1e-1);
		delta_within($location->{longt}, -0.1, 1e-1);

		my $address = $geocoder->reverse_geocode(latlng => '51.50,-0.13');
		like($address->{'city'}, qr/(City of Westminster|London)/i, 'test reverse');

		$ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocode.xyz', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);
		does_carp_that_matches(sub {
			$location = $geocoder->geocode('10 Downing St., London, UK');
		}, qr/^API returned error: on.+500/);
	}
}
