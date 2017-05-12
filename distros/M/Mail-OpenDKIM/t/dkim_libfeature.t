#!/usr/bin/perl -wT

use Test::More tests => 4;
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

LIBFEATURE: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my $rc = $o->dkim_libfeature({ feature => DKIM_FEATURE_DIFFHEADERS });

	ok(($rc == 0) || ($rc == 1));

	$o->dkim_close();
}

