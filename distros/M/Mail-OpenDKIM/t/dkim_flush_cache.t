#!/usr/bin/perl -wT

use Test::More tests => 4;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

FLUSH_CACHE: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	# Caching is not enabled
	ok($o->dkim_flush_cache() == -1);

	# TODO: enable caching and test flushing that

	$o->dkim_close();
}
