#!/usr/bin/perl -wT

use Test::More tests => 16;
use Error qw(:try);
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

my $msg = <<'EOF';
DKIM-Signature: v=1; a=rsa-sha1; c=relaxed; d=example.com; h=from:to:subject; s=example; bh=TozDQdcuD/NljOIYtF7AyqaxB8s=; b=dMk1p8wJdpHEFOk2pbtSScD3c2spKGkEo917Plae1weNhdrPvZOWvpZYnQL4/S9iQQtXpUByhjU0ObbWE/SgOhpFS216C847c+3RJCESNMJqxSzf65cuGPLffKQg4dboVKS759wC3hDhIMIPmdLABaK4crFAZcBnl+AQP1QpV4H9jUydiU1CqLURpZgeRd3uqhtua/wJTz3t7ad7YfPhQst7pYD7m97xp0PZURjPTYEKTHSJfhfT4zVDXl1+/HeNc3SV+nT9trpIj9ZOfmhotPYGE1PLX5ZyhZmskff7jQDALJxj6z2jICTCKhwLOtuENf9tCYiyYlMcYuij+hTSBg==
From: Nigel Horne <njh@bandsman.co.uk>
To: Tester <dktest@blackops.org>
Subject: Testing D

Can you hear me, Mother?
EOF

SIG_GETSIGNEDHDRS: {

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

	$msg =~ s/\n/\r\n/g;

	ok($d->dkim_chunk({ chunkp => $msg, len => length($msg)}) == DKIM_STAT_OK);

	ok($d->dkim_chunk({ chunkp => '', len => 0}) == DKIM_STAT_OK);

	ok($d->dkim_eom() == DKIM_STAT_NOKEY);

	$sig = $d->dkim_getsignature();

	ok(defined($sig));

	my $args = {
		sig => $sig,
		hdrs => pack('B' x 512, 0 x 512),
		hdrlen => 80,
		nhdrs => 2
	};

	TODO: {
		local $TODO = 'These tests are known to work with a valid private key';

		ok($d->dkim_sig_getsignedhdrs($args) == DKIM_STAT_NORESOURCE);

		$$args{nhdrs} = 4;

		ok($d->dkim_sig_getsignedhdrs($args) == DKIM_STAT_OK);

		ok(defined($$args{nhdrs}) && ($$args{nhdrs} == 3));	# from, to, subject
		like(substr($$args{hdrs}, 0, 80), qr/^From: Nigel Horne /);
		like(substr($$args{hdrs}, 80, 80), qr/^To: Tester /);
		like(substr($$args{hdrs}, 160, 80), qr/^Subject: Testing D/);
	};

	ok($d->dkim_free() == DKIM_STAT_OK);

	$o->dkim_close();
}
