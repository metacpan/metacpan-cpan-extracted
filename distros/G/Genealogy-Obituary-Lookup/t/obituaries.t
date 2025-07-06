#!perl -wT

use strict;
use Test::HTTPStatus;
use Test::Most tests => 23;

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

SKIP: {
	skip('Database not installed', 22) if(!-r 'lib/Genealogy/Obituary/Lookup/data/obituaries.sql');

	Database::Abstraction::init('directory' => 'lib/Genealogy/Obituary/Lookup/data');

	my $search;
	if($ENV{'TEST_VERBOSE'}) {
		$search = new_ok('Genealogy::Obituary::Lookup' => [ logger => MyLogger->new() ]);
	} else {
		$search = new_ok('Genealogy::Obituary::Lookup');
	}

	my @smiths = $search->search('Smith');

	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([\@smiths])->Dump());
	}

	cmp_ok(scalar(@smiths), '>=', 1, 'At least one Smith is found');

	# FIXME, test either last == Smith or maiden == Smith
	is($smiths[0]->{'last'}, 'Smith', 'Returned Smiths');

	# Test no matches returns undef
	ok(!defined($search->search('Xyzzy')));

	if($ENV{'MLARCHIVEDIR'} || ($ENV{'MLARCHIVE_DIR'})) {
		my $baal = $search->search({ first => 'Eric', last => 'Baal' });
		ok(defined($baal));

		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$baal])->Dump());
		}
		# cmp_ok($baal->{'url'}, 'eq', 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=96', 'Check Baal URL');
		cmp_ok($baal->{'url'}, 'eq', 'https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=96', 'Check Baal URL');
		# This will fail since the Wayback machine only has the first 18 or so pages archived
		# http_ok($baal->{'url'}, HTTP_OK);
	} else {
		SKIP: {
			diag('Removed test since Rootsweb was partially archived on Wayback Machine');
			skip('MLARCHIVEDIR or MLARCHIVE_DIR not set', 2);
		}
	}

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

	is(grep($_->{'url'} eq 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v28no008', @macfarlane), 1, 'Volume 28 is indexed');

	# V30
	my @krug = $search->search(first => 'Dan', middle => 'M', last => 'Krug', age => 80);

	is(grep($_->{'url'} eq 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v30no001', @krug), 1, 'Volume 30 is indexed');

	# Continuity line
	my $adams = $search->search({ first => 'Almetta', middle => 'Ivaleen', last => 'Adams' });
	is($adams->{'maiden'}, 'Paterson', 'Picks up maiden name');
	is($adams->{'url'}, 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v25no101', 'Check Adams URL');
	# Gives 403 error, even though it is there
	# http_ok($adams->{'url'}, HTTP_OK);

	# Locally added data
	my $erickson = $search->search(first => 'David', last => 'Erickson', age => 92);
	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([$erickson])->Dump());
	}
	cmp_ok($erickson->{'url'}, 'eq', 'https://www.beaconjournal.com/obituaries/pwoo0723808', 'Check locally added data');
	http_ok($erickson->{'url'}, HTTP_OK);

	# Funeral-notices.co.uk
	# https://funeral-notices.co.uk/notice/phillips/5229503
	my $phillips = $search->search(first => 'Robert', last => 'Phillips', age => 81);
	if($ENV{'TEST_VERBOSE'}) {
		diag(Data::Dumper->new([$phillips])->Dump());
	}
	cmp_ok($phillips->{'url'}, 'eq', 'https://funeral-notices.co.uk/notice/phillips/5229503');
	http_ok($phillips->{'url'}, HTTP_OK);

	my $taylor = $search->search(first => 'Margaret', middle => 'Elizabeth', last => 'Taylor');
	cmp_ok($taylor->{'url'}, 'eq', 'https://funeral-notices.co.uk/notice/taylor/5229508');
	http_ok($taylor->{'url'}, HTTP_OK);

	# Verify "Mc" is imported correctly
	my @mc_carthy = $search->search(first => 'Jean', middle => 'Emily', last => 'McCarthy');
	diag(Data::Dumper->new([\@mc_carthy])->Dump()) if($ENV{'TEST_VERBOSE'});
	http_ok($mc_carthy[0]->{'url'}, HTTP_OK);

	my $pass = 1;
	foreach my $entry(@mc_carthy) {
		if($entry->{'last'} ne 'McCarthy') {
			$pass = 0;
			last;
		}
	}
	# FIXME: Doesn't notice if any have been missed
	ok($pass, 'McCarthy is imported');

	my @empty = $search->search(last => 'xyzzy');
	is(scalar(@empty), 0, 'Search for xyzzy should return an empty list');
}
