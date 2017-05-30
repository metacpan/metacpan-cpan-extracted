#!perl -wT

use strict;
use warnings;
use Test::Most tests => 28;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

OSM: {
	SKIP: {
		skip 'Test requires Internet access', 26 unless(-e 't/online.enabled');

		eval {
			require Geo::Coder::OSM;

			Geo::Coder::OSM->import;

			require Test::Number::Delta;

			Test::Number::Delta->import();

			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();
		};

		if($@) {
			diag('Geo::Coder::OSM not installed - skipping tests');
			skip 'Geo::Coder::OSM not installed', 26;
		} else {
			diag("Using Geo::Coder::OSM $Geo::Coder::OSM::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List');
		# my $geocoder = new_ok('Geo::Coder::OSM' => [ 'sources' => [ 'mapquest', 'osm' ] ] );
		my $geocoder = new_ok('Geo::Coder::OSM');
		$geocoderlist->push($geocoder);

		ok(!defined($geocoderlist->geocode()));

		my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.02, 1e-1);

		my $ua = LWP::UserAgent::Throttled->new();
		$ua->throttle({ 'nominatim.openstreetmap.org' => 1 });
		$ua->env_proxy(1);
		$geocoderlist->ua($ua);

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
		ok($location->{address}{country_code} eq 'gb');
		ok($location->{address}{country} eq 'United Kingdom');

		$location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 39.00, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.10, 1e-1);
		ok($location->{address}{country_code} eq 'us');
		like($location->{address}{country}, qr/United States/, 'check USA');

		# Check list context finds both Portland, ME and Portland, OR
		my @locations = $geocoderlist->geocode('Portland, USA');

		ok(scalar(@locations) > 1);

		my ($maine, $oregon);
		foreach my $state(map { $_->{'address'}->{'state'} } @locations) {
			# diag($state);
			if($state eq 'Maine') {
				$maine++;
			} elsif($state eq 'Oregon') {
				$oregon++;
			}
		}

		ok($maine == 1);
		ok($oregon == 1);
	}
}
