#!perl -wT

use strict;
use warnings;
use Test::Most tests => 6;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::XYZ');
}

XYZ: {
	SKIP: {
		skip('Test requires Internet access', 4) unless(-e 't/online.enabled');

		my $geocoder = new_ok('Geo::Coder::XYZ');
		sleep(1);	# Avoid throttling

		# Check list context finds both Portland, ME and Portland, OR
		my @locations = $geocoder->geocode('Portland, US');

		ok(scalar(@locations) > 1);

		my $maine = 0;
		my $oregon = 0;

		foreach my $state(map { $_->{'state'} } @locations) {
			# diag($state);
			if($state eq 'ME') {
				$maine++;
			} elsif($state eq 'OR') {
				$oregon++;
			}
		}

		ok($maine == 1);
		ok($oregon == 1);

		if($ENV{'TEST_VERBOSE'}) {
			diag('There are Portlands in ', join (', ', map { $_->{'state'} } @locations));
		}
	}
}
