#!/usr/bin/perl -wT

use Test::More tests => 7;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

CACHE_STATS: {
	my ($queries, $hits, $expired, $keys);

	my $args = {
		queries => $queries,
		hits => $hits,
		expired => $expired,
		keys => $keys,
	};

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my $rc = $o->dkim_getcachestats($args);

	ok(($rc == DKIM_STAT_OK) || ($rc == DKIM_STAT_INVALID) || ($rc == DKIM_STAT_NOTIMPLEMENT));

	if($rc == DKIM_STAT_NOTIMPLEMENT) {
		diag('libOpenDKIM was not built with --enable-query_cache');
	}

	SKIP: {
		skip 'libOpenDKIM was not built with --enable-query_cache', 3 if($rc == DKIM_STAT_NOTIMPLEMENT);
		skip 'cache not yet initialized', 3 if($rc == DKIM_STAT_INVALID);
		skip 'dkim returned unknown status', 3 unless(($rc == DKIM_STAT_OK) || ($rc == DKIN_STAT_INVALID) || ($rc == DKIM_STAT_NOTIMPLEMENT));

		ok($$args{queries} == 0);
		ok($args{$hits} == 0);
		ok($args{$expired} == 0);
	}
}
