#!/usr/bin/perl
use v5.14;
use warnings;

use Test::More tests => 114;
use File::Slurper qw/read_binary/;

use IO::Compress::Brotli;
use IO::Uncompress::Brotli;

for my $test (<brotli/tests/testdata/*.compressed>) {
	my ($source) = $test =~ s/\.compressed$//r;
	$source = read_binary $source;

	for my $quality (9,11) {
		my $encoded = bro($source, $quality);
		my $decoded = unbro($encoded, 1_000_000);

		is $decoded, $source, "$test - quality $quality";
	}

	for my $quality (1,5,9,11) {
		my $enc = IO::Compress::Brotli->create;
		$enc->quality($quality);
		my $encoded = $enc->compress($source);
		$encoded .= $enc->finish();

		my $dec = IO::Uncompress::Brotli->create;
		my $decoded = $dec->decompress($encoded);

		is $decoded, $source, "$test - streaming / quality $quality";
	}
}
