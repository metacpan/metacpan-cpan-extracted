#!perl -wT

# Check the admin 2 database is sensible

use strict;
use warnings;
use Test::Most tests => 4;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free::DB::MaxMind::admin2');
}

ADMIN2: {
	SKIP: {
		if(!$ENV{'NO_NETWORK_TESTING'}) {
			my $admin2 = new_ok('Geo::Coder::Free::DB::MaxMind::admin2' => [{
				directory => 'lib/Geo/Coder/Free/MaxMind/databases',
				logger => new_ok('MyLogger'),
				no_entry => 1
			}]);

			my $kent = $admin2->fetchrow_hashref({ concatenated_codes => 'GB.ENG.G5' });
			cmp_ok($kent->{asciiname}, 'eq', 'Kent', 'GB.ENG.G5 is Kent');
		} else {
			diag('Network testing disabled');
			skip('Network testing disabled', 3);
		}
	}
}
