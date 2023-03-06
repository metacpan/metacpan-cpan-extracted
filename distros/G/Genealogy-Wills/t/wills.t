#!perl -wT

use strict;
use Test::Most tests => 6;

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::Wills');
}

SKIP: {
	skip 'Database not installed', 5 if(!-r 'lib/Genealogy/Wills/database/wills.sql');

	if($ENV{'TEST_VERBOSE'}) {
		use Data::Dumper;
		Genealogy::Wills::DB::init(logger => MyLogger->new());
	}
	my $search = new_ok('Genealogy::Wills');

	my @cowells = $search->search(last => 'Cowell');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@cowells])->Dump());
	}

	ok(scalar(@cowells) >= 1);
	is($cowells[0]->{'last'}, 'Cowell', 'Returned Cowells');

	my @carltons = $search->search(first => 'Stephen', last => 'Carlton', town => 'Ash, Kent, England');
	cmp_ok(scalar(@carltons), '==', 1, 'Stephen Carlton, Ash, Kent, England');

	@carltons = $search->search(first => 'Stephen', last => 'Carlton');
	cmp_ok(scalar(@carltons), '==', 4, 'Stephen Carlton');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@carltons])->Dump());
	}
}
