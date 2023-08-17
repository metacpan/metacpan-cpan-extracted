#!perl -wT

use strict;
use warnings;
use Test::Most tests => 21;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GOOGLE: {
	SKIP: {
		skip 'Test requires Internet access', 19 unless(-e 't/online.enabled');

		eval {
			require Geo::GeoNames;

			Geo::GeoNames->import;

			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Geo::GeoNames not installed - skipping tests');
			skip('Geo::GeoNames not installed', 19);
		} else {
			diag("Using Geo::GeoNames $Geo::GeoNames::VERSION");
		}
		if(my $username = $ENV{'GEONAMES_USER'}) {
			my $geocoderlist = new_ok('Geo::Coder::List')
				->push(Geo::GeoNames->new(username => $username));

			my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
			ok(defined($location));
			cmp_ok(ref($location), 'eq', 'HASH', 'Location is a hash');
			delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
			delta_within($location->{geometry}{location}{lng}, -77.02, 1e-1);
			is(ref($location->{'geocoder'}), 'Geo::GeoNames', 'Verify Geonames encoder is used');

			$location = $geocoderlist->geocode('Silver Spring, MD, USA');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
			delta_within($location->{geometry}{location}{lng}, -77.02, 1e-1);
			is($location->{'geocoder'}, undef, 'Verify subsequent reads are cached');

			$location = $geocoderlist->geocode('Plugh Hospice, Rochester, Earth');
			ok(!defined($location));

			$location = $geocoderlist->geocode({ location => 'Rochester, Kent, England' });
			ok(defined($location));
			cmp_ok(ref($location), 'eq', 'HASH', 'Location is a hash');
			delta_within($location->{geometry}{location}{lat}, 51.38, 1e-1);
			delta_within($location->{geometry}{location}{lng}, 0.5067, 1e-1);

			$location = $geocoderlist->geocode('Xyzzy Lane, Minster, Thanet, Kent, England');
			ok(!defined($location));

			ok(!defined($geocoderlist->geocode()));
			ok(!defined($geocoderlist->geocode('')));
		} else {
			diag('Set GEONAMES_USER to enable more tests');
			skip 'GEONAMES_USER not set', 19;
		}
	}
}
