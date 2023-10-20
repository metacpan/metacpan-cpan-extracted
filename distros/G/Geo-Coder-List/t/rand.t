#!perl -wT

use strict;
use warnings;
use Test::Most tests => 7;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

RAND: {
	SKIP: {
		skip('Test requires Internet access', 6) unless(-e 't/online.enabled');

		eval {
			require Geo::Coder::RandMcnally;

			Geo::Coder::RandMcnally->import();

			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Geo::Coder::RandMcnally not installed - skipping tests');
			skip('Geo::Coder::RandMcnally not installed', 6);
		} else {
			diag("Using Geo::Coder::RandMcnally $Geo::Coder::RandMcnally::VERSION");

			my $geocoderlist = new_ok('Geo::Coder::List');
			$geocoderlist->push(new_ok('Geo::Coder::RandMcnally'));

			TODO: {
				local $TODO = 'Geo::Coder::RandMcnally seems to have stopped working';

				if(my $location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA')) {
					# is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
					# delta_within($location->{geometry}{location}{lat}, 39.00, 1e-1);
					# delta_within($location->{geometry}{location}{lng}, -77.10, 1e-1);
					pass('RandMcnally unexpectedly pass Lat');
					pass('RandMcnally unexpectedly pass Long');
				} else {
					fail('RandMcnally Lat');
					fail('RandMcnally Long');
				}
			}

			ok(!defined($geocoderlist->geocode()));
			ok(!defined($geocoderlist->geocode('')));
		}
	}
}
