#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 5;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::ObituaryDailyTimes');
}

SKIP: {
	skip 'Database not installed', 3, if(!-r 'lib/Genealogy/ObituaryDailyTimes/database/obituaries.sql');

	if($ENV{'TEST_VERBOSE'}) {
		Genealogy::ObituaryDailyTimes::DB::init(logger => MyLogger->new());
	}
	my $search = new_ok('Genealogy::ObituaryDailyTimes');

	my @smiths = $search->search(last => 'Smith');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@smiths])->Dump());
	}

	ok(scalar(@smiths) >= 1);
	# FIXME, test either last == Smith or maiden == Smith
	is($smiths[0]->{'last'}, 'Smith', 'Returned Smiths');

	my $baal = $search->search({ first => 'Eric', last => 'Baal' });
	is($baal->{'url'}, 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=96', 'Check URL');
}
