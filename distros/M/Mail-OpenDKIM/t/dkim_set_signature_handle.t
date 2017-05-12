#!/usr/bin/perl -wT

use Test::More tests => 4;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

sub callback {
	my $closure = shift;

	die("callback called unexpectedly, closure $closure");
}

FLUSH_CACHE: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	ok($o->dkim_set_signature_handle({ func => \&callback }) == DKIM_STAT_OK);

	$o->dkim_close();
}

