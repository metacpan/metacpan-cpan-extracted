#!/usr/bin/perl -wT

use Test::More tests => 9;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

GETDOMAIN: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my ($s, $v);

	try {
		$s = $o->dkim_sign({
			id => 'MLM',
			secretkey => '11111',
			selector => 'example',
			domain => 'example.com',
			hdrcanon_alg => DKIM_CANON_RELAXED,
			bodycanon_alg => DKIM_CANON_RELAXED,
			sign_alg => DKIM_SIGN_RSASHA1,
			length => -1,
		});

		ok(defined($s));

		$v = $o->dkim_verify({
			id => 'MLM',
		});

		ok(defined($v));
	} catch Error with {
		my $ex = shift;
		fail($ex->stringify);
	};

	ok($v->dkim_getmode() == DKIM_MODE_VERIFY);

	ok($v->dkim_free() == DKIM_STAT_OK);

	ok($s->dkim_getmode() == DKIM_MODE_SIGN);

	ok($s->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}
