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
			skip('Geo::Coder::GeocodeFarm not installed', 21);
		} else {
			diag("Using Geo::Coder::GeocodeFarm $Geo::Coder::GeocodeFarm::VERSION");
			diag('Test connection to geocode.farm') if($ENV{'TEST_VERBOSE'});
			my $s = IO::Socket::INET->new(
				PeerAddr => 'www.geocode.farm:443',
				Timeout => 10
			);
			if(!defined($s)) {
				diag('Geofarm is down, disabling tests');
				skip('Geofarm is down, disabling tests', 21);
			}
		}
		my $ua = new_ok('LWP::UserAgent::Throttled');
		$ua->throttle({ 'www.geocode.farm' => 2 });	# Don't get blacklisted
		$ua->env_proxy(1);

		if(!$ua->get('https://www.geocode.farm')->is_success()) {
			diag('Geofarm is down, disabling tests');
			skip('Geofarm is down, disabling tests', 20);
		}

		my $geocoderlist = new_ok('Geo::Coder::List' => [ ua => $ua ]);
		my $geocoder = new_ok('Geo::Coder::GeocodeFarm');
		$geocoderlist->push($geocoder);

		ok(!defined($geocoderlist->geocode()));

		if(!$ENV{'AUTOMATED_TESTING'}) {
			my $location = $geocoderlist->geocode('Silver Spring, MD, USA');

			if($ENV{'TEST_VERBOSE'}) {
				diag(Data::Dumper->new([$location])->Dump());
			}
			ok(defined($location));
			ok(ref($location) eq 'HASH');

			delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
			delta_within($location->{geometry}{location}{lng}, -77.02, 1e-1);
			is(ref($location->{'geocoder'}), 'Geo::Coder::GeocodeFarm', 'Verify GeocodeFarm encoder is used');

			# $geocoderlist->ua($ua);	# not supported - https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues/1

			sleep(2);	# Don't get blacklisted - you can't set the UA so LWP::UserAgnet::Throttled won't help

			$location = $geocoderlist->geocode('10 Downing St, London, UK');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.50, 1e-1);
			delta_within($location->{geometry}{location}{lng}, -0.13, 1e-1);
			sleep(2);

			$location = $geocoderlist->geocode('Rochester, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.38, 1e-1);
			delta_within($location->{geometry}{location}{lng}, 0.5067, 1e-1);
			sleep(2);

			$location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 39.00, 1e-1);
			delta_within($location->{geometry}{location}{lng}, -77.10, 1e-1);
		} else {
			# It fails often, and I think the problem lies with geofarm
			diag('Not enabling this test for smokers');
			skip('Not enabling this test for smokers', 17);
		}
	}
}
