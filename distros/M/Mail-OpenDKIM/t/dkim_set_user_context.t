#!/usr/bin/perl -wT

use Test::More tests => 9;
use Error qw(:try);
use Data::Dumper;
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

SET_USER_CONTEXT: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my $d;

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

	isa_ok($d, 'Mail::OpenDKIM::DKIM');

	# ok(!defined($d->dkim_get_user_context()));

	my $ctx = pack('WWWWW', 1, 2, 3, 4, 5);
	my $args = { context => $ctx };

	ok($d->dkim_set_user_context($args) == DKIM_STAT_OK);

	my $c = $d->dkim_get_user_context();

	ok(defined($c));
	my @r = unpack('WWWWW', $c);
	ok($r[0] == 1);

	ok($d->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}
