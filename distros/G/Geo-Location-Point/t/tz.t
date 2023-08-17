#!perl -wT

use warnings;
use strict;
use Test::Most tests => 3;

BEGIN {
	use_ok('Geo::Location::Point');
}

TZ: {
	SKIP: {
		if(defined($ENV{'TIMEZONEDB_KEY'})) {
			# Ramsgate
			my $point = new_ok('Geo::Location::Point' => [
				latitude => 51.34,
				longitude => 1.42,
				key => $ENV{'TIMEZONEDB_KEY'}
			]);

			cmp_ok($point->tz(), 'eq', 'Europe/London', 'Ramsgate is in the UK timezone');
		} else {
			diag('Set TIMEZONEDB_KEY for your API key to timezonedb.com');
			skip('Set TIMEZONEDB_KEY for your API key to timezonedb.com', 2);
		}
	}
}
