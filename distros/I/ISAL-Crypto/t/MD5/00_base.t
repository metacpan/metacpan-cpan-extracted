#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "lib",
	"$FindBin::Bin/../blib/lib/",
	"$FindBin::Bin/../blib/arch/",
;

my (@features, @vecs, $numtests);
BEGIN {
	@vecs = (
		"",
		"d41d8cd98f00b204e9800998ecf8427e",
		"0",
		"cfcd208495d565ef66e7dff9f98764da",
		"abc",
		"900150983cd24fb0d6963f7d28e17f72",
		"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		"8215ef0796a20bcaaae116d3876c664a",
		"a" x 1000000,
		"7707d6ae4e027c70eea2a935c2296f21",
	);
	
	use ISAL::Crypto qw(:all);
	@features = ISAL::Crypto::get_cpu_features;
	$numtests = @vecs/2 * @features * 2;
}

use Test::More tests => $numtests;

for my $f (@features) {
	my @digests;
	my @ctx = (undef);
	my @vecf = @vecs;
	my $numtests_f = @vecf/2;
	
	my $init = "init_$f";
	my $mgr = ISAL::Crypto::Mgr::MD5->$init();
	
	my $submit = "submit_$f";
	for (1 .. $numtests_f) {
		push @ctx, ISAL::Crypto::Ctx::MD5->init();
		my $data = shift @vecf;
		push @digests, shift @vecf;
		$mgr->$submit($ctx[$_], $data, ENTIRE);
	}
	
	my $flush = "flush_$f";
	while ($mgr->$flush()){};
	
	for (1 .. $numtests_f) {
		my $res = unpack "H*", $ctx[$_]->get_digest();
		my $res_hex = $ctx[$_]->get_digest_hex();
		my $digest = shift @digests;
		ok($res eq $digest, "MD5-$f-$_");
		ok($res_hex eq $digest, "MD5-$f-$_-hex");
	}
}
