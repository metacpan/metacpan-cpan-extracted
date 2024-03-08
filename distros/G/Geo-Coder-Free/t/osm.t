#!perl -w

use warnings;
use strict;
use Test::Most tests => 4;
use Test::Number::Delta;
use Test::Carp;
use Test::Deep;
use lib 't/lib';
use MyLogger;
# use Test::Without::Module qw(Geo::libpostal);

BEGIN {
	use_ok('Geo::Coder::Free');
}

OPENADDR: {
	SKIP: {
		if($ENV{'OSM_HOME'}) {
			if($ENV{'TEST_VERBOSE'}) {
				Database::Abstraction::init(logger => MyLogger->new());
			}

			my $geo_coder = new_ok('Geo::Coder::Free' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);

			if($ENV{AUTHOR_TESTING}) {
				diag('This will take some time and memory');

				my $location = $geo_coder->geocode('Danville, PA, USA');
				ok(defined($location), 'Danville, PA, USA');
				cmp_deeply($location,
					methods('lat' => num(40.9, 1e-1), 'long' => num(-76.60, 1e-1)));
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 2);
			}
		} else {
			diag('Set OSM_HOME to enable openstreetmap.org testing');
			skip('Set OSM_HOME to enable openstreetmap.org testing', 3);
		}
	}
}
