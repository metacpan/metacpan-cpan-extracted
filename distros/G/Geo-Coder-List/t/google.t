#!perl -wT

use strict;
use warnings;
use Test::Most tests => 22;
use Test::NoWarnings;
use Test::Number::Delta within => 1e-2;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GOOGLE: {
	SKIP: {
		eval {
			require Geo::Coder::Google::V3;

			Geo::Coder::Google::V3->import;
		};

		if($@) {
			diag('Geo::Coder::Google::V3 not installed - skipping tests');
			skip 'Geo::Coder::Google::V3 not installed', 17;
		} else {
			diag("Using Geo::Coder::Google::V3 $Geo::Coder::Google::V3::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List')
			->push(new_ok('Geo::Coder::Google::V3'));

		my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 38.991);
		delta_ok($location->{geometry}{location}{lng}, -77.026);
		is(ref($location->{'geocoder'}), 'Geo::Coder::Google::V3', 'Verify Google encoder is used');

		$location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 38.991);
		delta_ok($location->{geometry}{location}{lng}, -77.026);
		is($location->{'geocoder'}, undef, 'Verify subsequent reads are cached');

		$location = $geocoderlist->geocode('Plugh Hospice, Rochester, New York');
		ok(!defined($location));

		$location = $geocoderlist->geocode({ location => 'Rochester, Kent, England' });
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 51.388);
		delta_ok($location->{geometry}{location}{lng}, 0.50672);

		$location = $geocoderlist->geocode('Xyzzy Lane, Minster, Thanet, Kent, England');
		ok(!defined($location));

		ok(!defined($geocoderlist->geocode()));
		ok(!defined($geocoderlist->geocode('')));
	}
}
