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
		"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
		"0",
		"5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9",
		"abc",
		"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
		"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
		"a" x 1000000,
		"cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0",
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
	my $mgr = ISAL::Crypto::Mgr::SHA256->$init();
	
	my $submit = "submit_$f";
	for (1 .. $numtests_f) {
		push @ctx, ISAL::Crypto::Ctx::SHA256->init();
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
		ok($res eq $digest, "SHA256-$f-$_");
		ok($res_hex eq $digest, "SHA256-$f-$_-hex");
	}
}
