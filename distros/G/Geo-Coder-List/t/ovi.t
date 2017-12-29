#!perl -wT

use strict;
use warnings;
use Test::Most tests => 25;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

OVI: {
	SKIP: {
		# skip 'Test requires Internet access', 23 unless(-e 't/online.enabled');
		skip 'Geo::Coder::Ovi has stopped working', 23;

		eval {
			require Geo::Coder::Ovi;

			Geo::Coder::Ovi->import;

			require Test::Number::Delta;

			Test::Number::Delta->import();

			require LWP::UserAgent::Throttled;

			LWP::UserAgent::Throttled->import();
		};

		if($@) {
			diag('Geo::Coder::Ovi not installed - skipping tests');
			skip 'Geo::Coder::Ovi not installed', 23;
		} else {
			diag("Using Geo::Coder::Ovi $Geo::Coder::Ovi::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List');
		my $geocoder = new_ok('Geo::Coder::Ovi');
		$geocoderlist->push($geocoder);

		ok(!defined($geocoderlist->geocode()));

		my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');

		delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.02, 1e-1);
		sleep(1);	# Don't get blacklisted

		my $ua = LWP::UserAgent::Throttled->new();
		$ua->throttle({ 'where.desktop.mos.svc.ovi.com' => 1 });
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

		$location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 39.00, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.10, 1e-1);

		# Check list context finds both Portland, ME and Portland, OR
		my @locations = $geocoderlist->geocode('Portland, USA');

		my $count = scalar(@locations);

		ok($count > 1);
		is(ref($locations[0]->{'geocoder'}), 'Geo::Coder::Ovi', 'Verify Ovi encoder is used');

		# my ($maine, $oregon);
		# foreach my $state(map { $_->{'address'}->{'state'} } @locations) {
			# # diag($state);
			# if($state eq 'Maine') {
				# $maine++;
			# } elsif($state eq 'Oregon') {
				# $oregon++;
			# }
		# }

		# ok($maine == 1);
		# ok($oregon == 1);

		@locations = $geocoderlist->geocode('Portland, USA');

		ok(scalar(@locations) == $count);
		is($locations[0]->{'geocoder'}, undef, 'Verify subsequent reads are cached');
	}
}
