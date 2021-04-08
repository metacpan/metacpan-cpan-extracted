#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 10;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::ObituaryDailyTimes');
}

SKIP: {
	skip 'Database not installed', 9, if(!-r 'lib/Genealogy/ObituaryDailyTimes/database/obituaries.sql');

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
	is($baal->{'url'}, 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=96', 'Check Baal URL');

	my $coppage = $search->search({ first => 'John', middle => 'W', last => 'Coppage' });
	is($coppage->{'middle'}, 'W', 'Test middle initial');
	is($coppage->{'url'}, 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v26no080', 'Check Coppage URL');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([$coppage])->Dump());
	}

	# Continuity line
	my $ackles = $search->search({ first => 'Almetta', middle => 'Ivaleen', last => 'Adams' });
	is($ackles->{'maiden'}, 'Paterson', 'Picks up maiden name');
	is($ackles->{'url'}, 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v25no101', 'Check Coppage URL');

	my @empty = $search->search(last => 'xyzzy');
	is(scalar(@empty), 0, 'Search for xyzzy should return an empty list');
}
