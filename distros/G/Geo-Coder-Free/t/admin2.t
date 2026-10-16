#!perl -wT

# Check the admin 2 database is sensible

use strict;
use warnings;
use Test::Most tests => 4;
use Test::Log::Abstraction;

BEGIN {
	use_ok('Geo::Coder::Free::DB::MaxMind::admin2');
}

ADMIN2: {
	SKIP: {
		if($ENV{'NO_NETWORK_TESTING'}) {
			diag('Network testing disabled');
			skip('Network testing disabled', 3);
		}

		skip('No admin2 database found', 3)
			unless -f 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db';

		{
			my $admin2 = new_ok('Geo::Coder::Free::DB::MaxMind::admin2' => [{
				directory => 'lib/Geo/Coder/Free/MaxMind/databases',
				logger => new_ok('Test::Log::Abstraction'),
				no_entry => 1
			}]);

			my $kent = $admin2->fetchrow_hashref({ concatenated_codes => 'GB.ENG.G5' });
			SKIP: {
				# GeoNames admin2 data evolves; GB.ENG.G5 may not be in the
				# current upstream download even though it was present historically.
				skip('GB.ENG.G5 not in current GeoNames data', 1)
					unless ref($kent) eq 'HASH' && defined $kent->{asciiname};
				cmp_ok($kent->{asciiname}, 'eq', 'Kent', 'GB.ENG.G5 is Kent');
			}
		}
	}
}
