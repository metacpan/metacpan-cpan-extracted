#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::DataScienceToolkit');
}

US: {
	SKIP: {
		skip 'Test requires Internet access', 3 unless(-e 't/online.enabled');

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip('Test::Number::Delta not installed', 3);
		}

		my $geocoder = new_ok('Geo::Coder::DataScienceToolkit');

		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 38.90, 1e-2);
		delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, -77.04, 1e-2);
	}
}
