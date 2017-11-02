#!perl -wT

use strict;
use warnings;
use Test::Most tests => 9;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

US: {
	SKIP: {
		skip 'Test requires Internet access', 7 unless(-e 't/online.enabled');

		eval {
			require Geo::Coder::US::Census;

			Geo::Coder::US::Census->import();

			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Geo::Coder::US::Census not installed - skipping tests');
			skip 'Geo::Coder::US::Census not installed', 7;
		} else {
			diag("Using Geo::Coder::US::Census $Geo::Coder::US::Census::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List');
		my $geocoder = new_ok('Geo::Coder::US::Census');
		$geocoderlist->push($geocoder);

		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
		delta_within($location->{result}{addressMatches}[0]->{coordinates}{y}, 38.90, 1e-1);	# Lat
		delta_within($location->{result}{addressMatches}[0]->{coordinates}{x}, -77.04, 1e-1);	# Long

		ok(!defined($geocoderlist->geocode()));
		ok(!defined($geocoderlist->geocode('')));
	}
}
