#!perl -wT

use strict;
use warnings;

use Test::Most;
use Test::RequiresInternet('api.geoapify.com' => 'https');
use Test::Needs 'Geo::Coder::GeoApify';

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GEOAPIFY: {
	SKIP: {
		skip 'Test requires Internet access', 19 unless(-e 't/online.enabled');

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import();

			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip 'Test::Number::Delta not installed', 19;
		} else {
			Geo::Coder::GeoApify->import();
			diag("Using Geo::Coder::GeoApify $Geo::Coder::GeoApify::VERSION");
		}

		if(my $key = $ENV{'GEOAPIFY_KEY'}) {
			my $ua = new_ok('LWP::UserAgent::Throttled');
			$ua->env_proxy(1);

			my $geocoderlist = new_ok('Geo::Coder::List')->push(new_ok('Geo::Coder::GeoApify' => [ apiKey => $key ]));
			$geocoderlist->ua($ua);
			$ua->throttle({ 'api.geoapify.com' => 2 });

			my $location = $geocoderlist->geocode('Ramsgate, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.33, 1e-2);
			delta_within($location->{geometry}{location}{lng}, 1.42, 1e-2);
			is(ref($location->{'geocoder'}), 'Geo::Coder::GeoApify', 'Verify GeoApify encoder is used');

			$location = $geocoderlist->geocode('Ashford, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.15, 1e-1);
			delta_within($location->{geometry}{location}{lng}, 0.87, 1e-1);
			is(ref($location->{'geocoder'}), 'Geo::Coder::GeoApify', 'Verify GeoApify encoder is used');

			$location = $geocoderlist->geocode('Ramsgate, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.33, 1e-2);
			delta_within($location->{geometry}{location}{lng}, 1.42, 1e-2);
			is($location->{'geocoder'}, 'cache', 'Verify subsequent reads are cached');

			if($ENV{'TEST_VERBOSE'}) {
				use Data::Dumper;
				diag('>>>>>>', Data::Dumper->new([$geocoderlist->reverse_geocode(latlng => '39.00,-77.10')])->Dump());
			}
			like($geocoderlist->reverse_geocode(latlng => '39.00,-77.10'), qr/Bethesda/i, 'test reverse geocode');
		} else {
			diag('Set GEOAPIFY_KEY to enable more tests');
			skip 'GEOAPIFY_KEY not set', 19;
		}
	}
}

done_testing();
