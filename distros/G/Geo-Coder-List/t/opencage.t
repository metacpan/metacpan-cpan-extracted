#!perl -wT

use strict;
use warnings;
use Test::Most tests => 16;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

BING: {
	SKIP: {
		skip 'Test requires Internet access', 14 unless(-e 't/online.enabled');

		eval {
			require Geo::Coder::OpenCage;

			Geo::Coder::OpenCage->import();

			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Geo::Coder::OpenCage not installed - skipping tests');
			skip 'Geo::Coder::OpenCage not installed', 14;
		} else {
			diag("Using Geo::Coder::OpenCage $Geo::Coder::OpenCage::VERSION");
		}

		if(my $key = $ENV{'GEO_CODER_OPENCAGE_API_KEY'}) {
			my $geocoderlist = new_ok('Geo::Coder::List');
			my $geocoder = new_ok('Geo::Coder::OpenCage' => [ api_key => $key ]);
			$geocoderlist->push($geocoder);

			my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 38.991, 1e-1);
			delta_within($location->{geometry}{location}{lng}, -77.026, 1e-1);

			$location = $geocoderlist->geocode('Wisdom Hospice, Rochester, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.396, 1e-1);
			delta_within($location->{geometry}{location}{lng}, 0.488, 1e-1);

			$location = $geocoderlist->geocode('St Mary The Virgin, Minster, Thanet, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_within($location->{geometry}{location}{lat}, 51.330, 1e-1);
			delta_within($location->{geometry}{location}{lng}, 1.31596, 1e-1);
		} else {
			diag('Set BMAP_KEY to enable more tests');
			skip 'BMAP_KEY not set', 14;
		}
	}
}
