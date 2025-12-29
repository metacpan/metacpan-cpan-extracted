#!/usr/bin/env perl

# Test translating location into TZ

use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::GeoNames');
}

SKIP: {
	if(my $user = $ENV{'GEONAMES_USER'}) {
		my $geo = new_ok('Geo::GeoNames' => [ username => $user ]);

		my $result = $geo->search(q => 'Laurel, MD', country => 'US', style => 'FULL');

		diag(Data::Dumper->new([$result])->Dump()) if($ENV{'TEST_VERBOSE'});

		my $found = 0;
		foreach my $entry(@{$result}) {
			if($entry->{'adminCode1'}->{'content'} eq 'MD') {
				cmp_ok($entry->{'timezone'}->{'content'}, 'eq', 'America/New_York', 'MD is in the Eastern timezone');
				$found = 1;
				last;
			}
		}
		cmp_ok($found, '==', 1, 'Found at least one result for Laurel, MD');
	} else {
		skip('$ENV{GEONAME_USER} needed to test timezones', 3);
	}
}
