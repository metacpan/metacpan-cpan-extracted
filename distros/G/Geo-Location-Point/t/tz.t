#!/usr/bin/env perl

use warnings;
use strict;
use Test::Most tests => 3;

BEGIN {
	use_ok('Geo::Location::Point');
}

TZ: {
	SKIP: {
		if(my $key = $ENV{'TIMEZONEDB_KEY'}) {
			eval {
				require TimeZone::TimeZoneDB;
			};
			if($@) {
				skip('TimeZone::TimeZoneDB not installed', 2);
			} else {
				TimeZone::TimeZoneDB->import();
				# Ramsgate
				my $point = new_ok('Geo::Location::Point' => [
					latitude => 51.34,
					longitude => 1.42,
					key => $key
				]);

				cmp_ok($point->tz(), 'eq', 'Europe/London', 'Ramsgate is in the UK timezone');
				done_testing();
			}
		} else {
			skip('Set TIMEZONEDB_KEY for your API key to timezonedb.com', 2);
		}
	}
}
