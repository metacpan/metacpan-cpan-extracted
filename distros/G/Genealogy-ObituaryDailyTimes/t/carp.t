#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;

BEGIN {
	use_ok('Genealogy::ObituaryDailyTimes');
}

CARP: {
	eval 'use Test::Carp';

	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		my $search = new_ok('Genealogy::ObituaryDailyTimes');

		does_carp_that_matches(sub { my @empty = $search->search(); }, qr/^Value for 'last' is mandatory/);
		does_carp_that_matches(sub { my @empty = $search->search(last => undef); }, qr/^Value for 'last' is mandatory/);
		does_carp_that_matches(sub { my @empty = $search->search({ last => undef }); }, qr/^Value for 'last' is mandatory/);
		done_testing();
	}
}
