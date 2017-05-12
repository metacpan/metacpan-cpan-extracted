#!/usr/bin/perl -wT

use Test::More tests => 15;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

ATPS_CHECK: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my $d;

	try {
		$d = $o->dkim_verify({
			id => 'MLM',
		});

		ok(defined($d));

		# d is a Mail::OpenDKIM::DKIM object
	} catch Error with {
		my $ex = shift;
		fail($ex->stringify);
	};

	isa_ok($d, 'Mail::OpenDKIM::DKIM');

	my $hdr = "DKIM-Signature: v=1; a=rsa-sha1; c=relaxed; d=example.com; h=from:to:subject; s=example; bh=TozDQdcuD/NljOIYtF7AyqaxB8s=; b=dMk1p8wJdpHEFOk2pbtSScD3c2spKGkEo917Plae1weNhdrPvZOWvpZYnQL4/S9iQQtXpUByhjU0ObbWE/SgOhpFS216C847c+3RJCESNMJqxSzf65cuGPLffKQg4dboVKS759wC3hDhIMIPmdLABaK4crFAZcBnl+AQP1QpV4H9jUydiU1CqLURpZgeRd3uqhtua/wJTz3t7ad7YfPhQst7pYD7m97xp0PZURjPTYEKTHSJfhfT4zVDXl1+/HeNc3SV+nT9trpIj9ZOfmhotPYGE1PLX5ZyhZmskff7jQDALJxj6z2jICTCKhwLOtuENf9tCYiyYlMcYuij+hTSBg==\r\n";
	ok($d->dkim_header({ header => $hdr, len => length($hdr) }) == DKIM_STAT_OK);

	$hdr = "From: Nigel Horne <njh\@example.com>\r\n";
	ok($d->dkim_header({ header => $hdr, len => length($hdr) }) == DKIM_STAT_OK);

	$hdr = "To: Tester <dktest\@blackops.org>\r\n";
	ok($d->dkim_header({ header => $hdr, len => length($hdr) }) == DKIM_STAT_OK);

	my $args = {
		sigs => undef,
		nsigs => undef
	};

	ok($d->dkim_eoh() == DKIM_STAT_OK);

	ok($d->dkim_getsiglist($args) == DKIM_STAT_OK);

	ok(defined($$args{sigs}));

	ok($$args{nsigs} == 1);

	my @sigs = @{$$args{sigs}};

	my $res;
	my $aargs = { sig => $sigs[0], res => $res, timeout => undef };

	# FIXME: Fails with sig is not of type DKIM_SIGINFO, which most likely means that
	#	either it or dkim_getsiglist (or both) aren't working
	TODO: {
		todo_skip 'dkim_atps_check fails with sig is not of type DKIM_SIGINFO - skip until dkim_getsiglist is fixed', 2;
		my $rc = $d->dkim_atps_check($aargs);

		ok(($rc == DKIM_STAT_OK) || ($rc == DKIM_STAT_NOTIMPLEMENT));
	}

	ok($d->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}
