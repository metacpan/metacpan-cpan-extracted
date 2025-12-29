#!/usr/bin/env perl

# Test translating location into TZ

use strict;
use warnings;
use Test::Most tests => 4;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::GeoNames');
}

SKIP: {
	if(my $user = $ENV{'GEONAMES_USER'}) {
		my $geo = new_ok('Geo::GeoNames' => [ username => $user ]);

		my $result = $geo->search(q => '10 Downing Street, London', style => 'FULL');

		diag(Data::Dumper->new([$result])->Dump()) if($ENV{'TEST_VERBOSE'});

		$result = @{$result}[0];
		cmp_ok($result->{'countryName'}, 'eq', 'United Kingdom', 'Finds PM house');
	} else {
		skip('$ENV{GEONAME_USER} needed to test finding countries', 2);
	}
}
