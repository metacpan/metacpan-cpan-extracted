#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::Needs 'Test::Carp';

BEGIN {
	use_ok('Genealogy::ObituaryDailyTimes');
}

SKIP: {
	skip 'Database not installed', 4 if(!-r 'lib/Genealogy/ObituaryDailyTimes/data/obituaries.sql');

	Test::Carp->import();

	my $search = new_ok('Genealogy::ObituaryDailyTimes' => [ directory => 'lib/Genealogy/ObituaryDailyTimes/data' ]);

	does_carp_that_matches(sub { my @empty = $search->search(); }, qr/^Value for 'last' is mandatory/);
	does_carp_that_matches(sub { my @empty = $search->search(last => undef); }, qr/^Value for 'last' is mandatory/);
	does_carp_that_matches(sub { my @empty = $search->search({ last => undef }); }, qr/^Value for 'last' is mandatory/);
	done_testing();
}
