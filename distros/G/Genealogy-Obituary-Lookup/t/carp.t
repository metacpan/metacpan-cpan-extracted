#!perl -wT

use strict;
use warnings;
use Test::Most tests => 6;
use Test::Needs 'Test::Carp';

BEGIN {
	use_ok('Genealogy::Obituary::Lookup');
}

SKIP: {
	Test::Carp->import();

	does_carp_that_matches(sub { my $o = Genealogy::Obituary::Lookup->new({ directory => '/not_there' }); }, qr/ is not a directory$/);

	skip('Database not installed', 4) if(!-r 'lib/Genealogy/Obituary/Lookup/data/obituaries.sql');

	my $search = new_ok('Genealogy::Obituary::Lookup' => [ directory => 'lib/Genealogy/Obituary/Lookup/data' ]);

	does_croak_that_matches(sub { my @empty = $search->search(); }, qr/^Usage: .*last/);
	does_carp_that_matches(sub { my @empty = $search->search(last => undef); }, qr/^Value for 'last' is mandatory/);
	does_carp_that_matches(sub { my @empty = $search->search({ last => undef }); }, qr/^Value for 'last' is mandatory/);
	done_testing();
}
