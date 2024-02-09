#!perl -wT

use strict;
use Test::Most tests => 13;

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Genealogy::ObituaryDailyTimes');
}

SKIP: {
	skip 'Database not installed', 12 if(!-r 'lib/Genealogy/ObituaryDailyTimes/data/obituaries.sql');

	my $search;
	if($ENV{'TEST_VERBOSE'}) {
		$search = new_ok('Genealogy::ObituaryDailyTimes' => [ logger => MyLogger->new() ]);
	} else {
		$search = new_ok('Genealogy::ObituaryDailyTimes');
	}

	my @smiths = $search->search(last => 'Smith');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@smiths])->Dump());
	}

	ok(scalar(@smiths) >= 1);

	# FIXME, test either last == Smith or maiden == Smith
	is($smiths[0]->{'last'}, 'Smith', 'Returned Smiths');

	unless($ENV{'MLARCHIVEDIR'} || ($ENV{'MLARCHIVE_DIR'})) {
		diag('The next test may fail since Rootsweb was partially archived on Wayback Machine');
	}
	my $baal = $search->search({ first => 'Eric', last => 'Baal' });
	ok(defined($baal));

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([$baal])->Dump());
	}
	cmp_ok($baal->{'url'}, 'eq', 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=96', 'Check Baal URL');

	my @coppage = $search->search({ first => 'John', middle => 'W', last => 'Coppage' });

	cmp_ok(scalar(@coppage), '>', 0, 'At least one John Coppage');
	is(grep($_->{'middle'} eq 'W', @coppage), scalar(@coppage), 'Every match has the correct middle initial');
	is(grep($_->{'url'} eq 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v26no080', @coppage), 1, 'Find the expected URL exactly one time');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@coppage])->Dump());
	}

	# V28
	my @macfarlane = $search->search({ first => 'Morley Alexander', middle => 'Victor', last => 'MacFarlane', age => 85 });

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@macfarlane])->Dump());
	}

	is(grep($_->{'url'} eq 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v28no008', @macfarlane), 1, 'Find the expected URL exactly one time');

	# Continuity line
	my $adams = $search->search({ first => 'Almetta', middle => 'Ivaleen', last => 'Adams' });
	is($adams->{'maiden'}, 'Paterson', 'Picks up maiden name');
	is($adams->{'url'}, 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v25no101', 'Check Adams URL');

	my @empty = $search->search(last => 'xyzzy');
	is(scalar(@empty), 0, 'Search for xyzzy should return an empty list');
}
