#!/usr/bin/perl -wT

# TODO: test by adding z= to the signature header

use Test::More tests => 11;
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

OHDRS: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init(),'Init');

	my $d;

	try {
		$d = $o->dkim_verify({
			id => 'MLM',
		});

		ok(defined($d),'Verify');

		# d is a Mail::OpenDKIM::DKIM object
	} catch Error with {
		my $ex = shift;
		fail($ex->stringify);
	};

	isa_ok($d, 'Mail::OpenDKIM::DKIM');

	$msg =~ s/\n/\r\n/g;

	ok($d->dkim_chunk({ chunkp => $msg, len => length($msg)}) == DKIM_STAT_OK,'Msg Chunk');

	ok($d->dkim_chunk({ chunkp => '', len => 0}) == DKIM_STAT_OK,'Empty Chunk');

	ok($d->dkim_eom() == DKIM_STAT_NOKEY,'EOM');

	my $sig = $d->dkim_getsignature();

	my @ptrs = ( '', '', '', '', '' );
	my $args = {
		sig => $sig,
		ptrs => \@ptrs,
		cnt => 5
	};

	ok($d->dkim_ohdrs($args) == DKIM_STAT_OK,'ohdrs');

	# There are no z= headers
	ok($$args{cnt} == 0,'no z= headers');

	ok($d->dkim_free() == DKIM_STAT_OK,'free');

	$o->dkim_close();
}
