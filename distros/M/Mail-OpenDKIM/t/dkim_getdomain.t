#!/usr/bin/perl -wT

use Test::More tests => 15;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

GETDOMAIN: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my ($d1, $d2);

	try {
		$d1 = $o->dkim_verify({
			id => 'MLM',
		});

		ok(defined($d1));

		$d2 = $o->dkim_verify({
			id => 'MLM',
		});

		ok(defined($d2));
	} catch Error with {
		my $ex = shift;
		fail($ex->stringify);
	};

	ok(!defined($d1->dkim_getdomain()));

	my $header = 'From: Nigel Horne <njh@example.com>'; 
	ok($d1->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);

	$header = 'From: Nigel Horne <njh@xyzzy.com>'; 
	ok($d2->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);

	$header = 'To: Tester <dktest@blackops.org>';
	ok($d1->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);
	ok($d2->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);

	$d1->dkim_eoh();

	ok(!defined($d2->dkim_getdomain()));

	$d2->dkim_eoh();

	ok($d1->dkim_getdomain() eq 'example.com');
	ok($d2->dkim_getdomain() eq 'xyzzy.com');

	ok($d2->dkim_free() == DKIM_STAT_OK);
	ok($d1->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}
