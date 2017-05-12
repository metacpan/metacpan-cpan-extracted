#!/usr/bin/perl -wT

use Test::More tests => 4;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

sub callback {
	my ($dkim, $siginfo, $buf, $buflen) = @_;

	die("callback called unexpectedly, buf $buf");
}

FLUSH_CACHE: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	ok($o->dkim_set_key_lookup({ func => \&callback }) == DKIM_STAT_OK);

	$o->dkim_close();
}

