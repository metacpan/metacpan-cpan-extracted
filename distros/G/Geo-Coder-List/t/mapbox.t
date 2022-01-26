#!perl -wT

use strict;
use warnings;
use Test::Most tests => 20;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

MAPBOX: {
	SKIP: {
		eval {
			require Geo::Coder::Mapbox;

			Geo::Coder::Mapbox->import();

			require Test::Number::Delta;

			Test::Number::Delta->import();

			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();
		};

		if($@) {
			diag('Geo::Coder::Mapbox not installed - skipping tests');
			skip 'Geo::Coder::Mapbox not installed', 18;
		} else {
			diag("Using Geo::Coder::Mapbox $Geo::Coder::Mapbox::VERSION");
		}
		if(my $key = $ENV{MAPBOX}) {
			my $ua = new_ok('LWP::UserAgent::Throttled');
			$ua->env_proxy(1);

			my $geocoderlist = new_ok('Geo::Coder::List')->push(new_ok('Geo::Coder::Mapbox' => [ access_token => $key ]));
			$geocoderlist->ua($ua);
			$ua->throttle({ 'api.mapbox.com' => 1 });

			my $location = $geocoderlist->geocode('Ramsgate, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.34, 1e-2);
			delta_within($location->{geometry}{location}{lng}, 1.40, 1e-2);
			is(ref($location->{'geocoder'}), 'Geo::Coder::Mapbox', 'Verify Mapbox encoder is used');

			$location = $geocoderlist->geocode('Ashford, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.15, 1e-2);
			delta_within($location->{geometry}{location}{lng}, 0.87, 1e-2);
			is(ref($location->{'geocoder'}), 'Geo::Coder::Mapbox', 'Verify Mapbox encoder is used');

			$location = $geocoderlist->geocode('Ramsgate, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.34, 1e-2);
			delta_within($location->{geometry}{location}{lng}, 1.40, 1e-2);
			is($location->{'geocoder'}, undef, 'Verify subsequent reads are cached');
		} else {
			diag('Set MAPBOX to enable more tests');
			skip('MAPBOX not set', 18);
		}
	}
}
