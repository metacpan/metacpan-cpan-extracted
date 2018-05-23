#!/usr/bin/perl
use v5.14;
use warnings;

use Test::More tests => 84;
use File::Slurper qw/read_binary/;

use IO::Uncompress::Brotli;

for my $test (<brotli/tests/testdata/*.compressed*>) {
	my ($expected) = $test =~ s/\.compressed.*//r;
	$expected = read_binary $expected;

	my $decoded = unbro ((scalar read_binary $test), 1_000_000);
	is $decoded, $expected, "$test";

	open FH, '<', $test;
	my $unbro = IO::Uncompress::Brotli->create;
	my ($buf, $out);
	until (eof FH) {
		read FH, $buf, 100;
		$out .= $unbro->decompress($buf);
	}
	is $out, $expected, "$test (streaming)";
}
