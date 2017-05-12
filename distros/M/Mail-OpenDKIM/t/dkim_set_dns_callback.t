#!/usr/bin/perl -wT

use Test::More tests => 5;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

sub callback {
	my $ctx = shift;

	die("callback called unexpectedly, ctx $ctx");
}

FLUSH_CACHE: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	ok($o->dkim_set_dns_callback({ func => \&callback, interval => 0 }) == DKIM_STAT_INVALID);
	ok($o->dkim_set_dns_callback({ func => \&callback, interval => 1 }) == DKIM_STAT_OK);

	$o->dkim_close();
}

