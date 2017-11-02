#!perl -wT

use strict;
use warnings;
use Test::Most tests => 23;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GEOCODEFARM: {
	SKIP: {
		skip 'Test requires Internet access', 21 unless(-e 't/online.enabled');

		eval {
			require Geo::Coder::GeocodeFarm;

			Geo::Coder::GeocodeFarm->import;

			require Test::Number::Delta;

			Test::Number::Delta->import();

			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();
		};

		if($@) {
			diag('Geo::Coder::GeocodeFarm not installed - skipping tests');
			skip 'Geo::Coder::GeocodeFarm not installed', 21;
		} else {
			diag("Using Geo::Coder::GeocodeFarm $Geo::Coder::GeocodeFarm::VERSION");
		}
		my $ua = new_ok('LWP::UserAgent::Throttled');
		$ua->throttle({ 'www.geocode.farm' => 1 });
		$ua->env_proxy(1);

		my $geocoderlist = new_ok('Geo::Coder::List' => [ ua => $ua ]);
		my $geocoder = new_ok('Geo::Coder::GeocodeFarm');
		$geocoderlist->push($geocoder);

		ok(!defined($geocoderlist->geocode()));

		my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');

		delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.02, 1e-1);
		sleep(1);	# Don't get blacklisted

		# $geocoderlist->ua($ua);	# not supported - https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues/1

		$location = $geocoderlist->geocode('10 Downing St, London, UK');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 51.50, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -0.13, 1e-1);

		$location = $geocoderlist->geocode('Rochester, Kent, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 51.38, 1e-1);
		delta_within($location->{geometry}{location}{lng}, 0.5067, 1e-1);

		$location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 39.00, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.10, 1e-1);

		is(ref($location->{'geocoder'}), 'Geo::Coder::GeocodeFarm', 'Verify GeocodeFarm encoder is used');
	}
}
