#!/usr/bin/perl -wT

use Test::More tests => 6;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

sub callback {
	my ($dkim, $siginfo, $nsigs) = @_;

	die("callback called unexpectedly, nsigs $nsigs");
}

SET_FINAL: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	try {
		$d = $o->dkim_sign({
			id => 'MLM',
			secretkey => '11111',
			selector => 'example',
			domain => 'example.com',
			hdrcanon_alg => DKIM_CANON_RELAXED,
			bodycanon_alg => DKIM_CANON_RELAXED,
			sign_alg => DKIM_SIGN_RSASHA1,
			length => -1,
		});

		ok(defined($d));

		# d is a Mail::OpenDKIM::DKIM object
	} catch Error with {
		my $ex = shift;
		fail($ex->stringify);
	};

	ok($d->dkim_set_final({ func => \&callback }) == DKIM_STAT_OK);

	ok($d->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}

