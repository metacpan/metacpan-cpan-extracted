#!perl -wT

use strict;
use warnings;
use Test::Most;
use Test::Needs 'Test::Carp';

BEGIN {
	use_ok('Genealogy::Wills');
}

# Import after use_ok so the module is loaded first
Test::Carp->import();

# new() directory-not-found carp does not require the real DB to be present.
# Carp::carp must be fully-qualified in the module for Test::Carp to intercept it.
does_carp_that_matches(
	sub { Genealogy::Wills->new(directory => '/does/not/exist') },
	qr/is not a directory/
);

SKIP: {
	skip 'Database not installed', 4 if(!-r 'lib/Genealogy/Wills/data/wills.sql');

	my $search = new_ok('Genealogy::Wills' => [ directory => 'lib/Genealogy/Wills/data' ]);

	does_croak_that_matches(sub { my @empty = $search->search(); }, qr/^Usage: /);
	does_carp_that_matches(sub { my @empty = $search->search(last => undef); }, qr/^Value for 'last' is mandatory/);
	does_carp_that_matches(sub { my @empty = $search->search({ last => undef }); }, qr/^Value for 'last' is mandatory/);
}

done_testing();
