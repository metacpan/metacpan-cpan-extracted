#!perl -wT

# Check the admin 1 database is sensible

use strict;
use warnings;
use Test::Most tests => 6;
use Test::Log::Abstraction;

use constant	DATABASE => 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db';

BEGIN {
	use_ok('Geo::Coder::Free::DB::MaxMind::admin1');
}

ADMIN1: {
	SKIP: {
		if($ENV{'NO_NETWORK_TESTING'}) {
			diag('Network testing disabled');
			skip('Network testing disabled', 5);
		}

		skip('No admin1 database found', 5)
			unless -f 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db';

		{
			my $admin1 = new_ok('Geo::Coder::Free::DB::MaxMind::admin1' => [
				directory => 'lib/Geo/Coder/Free/MaxMind/databases',
				logger => new_ok('Test::Log::Abstraction'),
				no_entry => 1
			]);

			my $england = $admin1->fetchrow_hashref({ concatenated_codes => 'GB.ENG' });
			cmp_ok($england->{asciiname}, 'eq', 'England', 'GB.ENG is England');
			cmp_ok($admin1->asciiname(concatenated_codes => 'GB.ENG'), 'eq', 'England', 'GB.ENG is England - AUTOLOAD');

			$england = $admin1->fetchrow_hashref({ asciiname => 'England' });
			cmp_ok($england->{concatenated_codes}, 'eq', 'GB.ENG', 'England is GB.ENG');
		}
	}
}
