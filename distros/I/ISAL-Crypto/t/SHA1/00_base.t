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
		"da39a3ee5e6b4b0d3255bfef95601890afd80709",
		"0",
		"b6589fc6ab0dc82cf12099d1c2d40ab994e8410c",
		"abc",
		"a9993e364706816aba3e25717850c26c9cd0d89d",
		"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		"84983e441c3bd26ebaae4aa1f95129e5e54670f1",
		"a" x 1000000,
		"34aa973cd4c4daa4f61eeb2bdbad27316534016f",
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
	my $mgr = ISAL::Crypto::Mgr::SHA1->$init();
	
	my $submit = "submit_$f";
	for (1 .. $numtests_f) {
		push @ctx, ISAL::Crypto::Ctx::SHA1->init();
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
		ok($res eq $digest, "SHA1-$f-$_");
		ok($res_hex eq $digest, "SHA1-$f-$_-hex");
	}
}
