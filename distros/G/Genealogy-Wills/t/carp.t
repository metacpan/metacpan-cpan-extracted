#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::Needs 'Test::Carp';

BEGIN {
	use_ok('Genealogy::Wills');
}

SKIP: {
	skip 'Database not installed', 4 if(!-r 'lib/Genealogy/Wills/data/wills.sql');

	Test::Carp->import();

	my $search = new_ok('Genealogy::Wills' => [ directory => 'lib/Genealogy/Wills/data' ]);

	does_croak_that_matches(sub { my @empty = $search->search(); }, qr/^Usage: /);
	does_carp_that_matches(sub { my @empty = $search->search(last => undef); }, qr/^Value for 'last' is mandatory/);
	does_carp_that_matches(sub { my @empty = $search->search({ last => undef }); }, qr/^Value for 'last' is mandatory/);
	done_testing();
}
