#!perl -w

use warnings;
use strict;
use Test::Most tests => 14;

BEGIN {
	use_ok('Geo::Coder::DataScienceToolkit');
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

		my $geocoder = new_ok('Geo::Coder::DataScienceToolkit');

		my $location = $geocoder->geocode('Ramsgate, Kent, England');
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 51.34, 1e-2);
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, 1.42, 1e-2);

		$location = $geocoder->geocode({ location => '10 Downing St., London, UK' });
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 51.51, 1e-2);
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, -0.13, 1e-2);

		$location = $geocoder->geocode(location => 'Wokingham, Berkshire, England');
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 51.50, 1e-2);
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, -1.25, 1e-2);

		$location = $geocoder->geocode(location => '10 Downing St., London, UK');
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 51.51, 1e-2);
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, -0.13, 1e-2);

		does_carp_that_matches(sub {
			$location = $geocoder->reverse_geocode(latlng => '51.50,-0.13');
		}, qr/does not support reverse/);

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('www.datasciencetoolkit.org', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);
		does_carp_that_matches(sub {
			$location = $geocoder->geocode('10 Downing St., London, UK');
		}, qr/^API returned error: on.+500/);
	}
}
