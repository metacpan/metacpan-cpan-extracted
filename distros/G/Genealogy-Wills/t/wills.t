#!perl -wT

use strict;
use Test::Most tests => 4;

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::Wills');
}

SKIP: {
	skip 'Database not installed', 3 if(!-r 'lib/Genealogy/Wills/database/wills.sql');

	if($ENV{'TEST_VERBOSE'}) {
		Genealogy::Wills::DB::init(logger => MyLogger->new());
	}
	my $search = new_ok('Genealogy::Wills');

	my @cowells = $search->search(last => 'Cowell');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@cowells])->Dump());
	}

	ok(scalar(@cowells) >= 1);
	is($cowells[0]->{'last'}, 'Cowell', 'Returned Cowells');
}
