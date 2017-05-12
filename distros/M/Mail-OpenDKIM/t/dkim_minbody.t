#!/usr/bin/perl -wT

use Test::More tests => 18;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

MINBODY: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my($d1, $d2);

	try {
		$d1 = $o->dkim_verify({
			id => 'MLM',
		});
		$d2 = $o->dkim_verify({
			id => 'MLM',
		});

		ok(defined($d1));

		ok(defined($d1->dkim_getid()));

		ok(defined($d2));

	} catch Error with {
		my $ex = shift;
		fail($ex->stringify);
	};

	my $header = 'From: Nigel Horne <njh@example.com>';
	ok($d1->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);
	ok($d2->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);

	$header = 'To: Tester <dktest@blackops.org>';
	ok($d1->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);
	ok($d2->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);
	
	$header = 'DKIM-Signature: v=1; a=rsa-sha1; c=relaxed; d=example.com; h=from:to:subject; s=example; bh=TozDQdcuD/NljOIYtF7AyqaxB8s=; b=dMk1p8wJdpHEFOk2pbtSScD3c2spKGkEo917Plae1weNhdrPvZOWvpZYnQL4/S9iQQtXpUByhjU0ObbWE/SgOhpFS216C847c+3RJCESNMJqxSzf65cuGPLffKQg4dboVKS759wC3hDhIMIPmdLABaK4crFAZcBnl+AQP1QpV4H9jUydiU1CqLURpZgeRd3uqhtua/wJTz3t7ad7YfPhQst7pYD7m97xp0PZURjPTYEKTHSJfhfT4zVDXl1+/HeNc3SV+nT9trpIj9ZOfmhotPYGE1PLX5ZyhZmskff7jQDALJxj6z2jICTCKhwLOtuENf9tCYiyYlMcYuij+hTSBg==';
	ok($d1->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);

	$header = 'Subject: Testing D';
	ok($d1->dkim_header({ header => $header, len => length($header) }) == DKIM_STAT_OK);

	ok($d1->dkim_eoh() == DKIM_STAT_OK);
	ok($d2->dkim_eoh() == DKIM_STAT_NOSIG);

	my $m = $d1->dkim_minbody();

	ok(($m == 4294967295) || ($m == 18446744073709551615));	# Posix::ULONG_MAX
	ok($d2->dkim_minbody() == 0);

	ok($d1->dkim_free() == DKIM_STAT_OK);
	ok($d2->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}
