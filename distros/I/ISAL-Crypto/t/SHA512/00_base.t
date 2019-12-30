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
		"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e",
		"0",
		"31bca02094eb78126a517b206a88c73cfa9ec6f704c7030d18212cace820f025f00bf0ea68dbf3f3a5436ca63b53bf7bf80ad8d5de7d8359d0b7fed9dbc3ab99",
		"abc",
		"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
		"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		"204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445",
		"a" x 1000000,
		"e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b",
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
	my $mgr = ISAL::Crypto::Mgr::SHA512->$init();
	
	my $submit = "submit_$f";
	for (1 .. $numtests_f) {
		push @ctx, ISAL::Crypto::Ctx::SHA512->init();
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
		ok($res eq $digest, "SHA512-$f-$_");
		ok($res_hex eq $digest, "SHA512-$f-$_-hex");
	}
}
