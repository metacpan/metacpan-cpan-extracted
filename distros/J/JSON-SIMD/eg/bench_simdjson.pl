#!/usr/bin/perl

use strict;
use warnings;
use feature qw/say/;
use JSON::SIMD;
use Time::HiRes;
use File::Basename;

my %files;
for my $f (@ARGV) {
	my $json;
	{
		local $/;
		open my $F, '<', $f or die "Can't open $f";
		$json = <$F>;
		close $F;
	}
	my $name = basename($f);
	$files{$name} = $json;
}

printf "% 15s %10s %10s %10s %6s\n", qw/test_case length original simdjson diff%/;
say '-' x 60;
for my $f (sort keys %files) {
	my $json = $files{$f};
	my $orig = run(JSON::SIMD->new->utf8->use_simdjson(0), $json);
	my $simd = run(JSON::SIMD->new->utf8,                  $json);
	my $diff = 100 * ($simd - $orig) / $orig;
	printf "% 15s %10d %10.2f %10.2f %6.2f\n", $f, length($json), $orig, $simd, $diff;
}


sub run {
	my ($decoder, $json, $times) = @_;
	$times //= int(100_000_000/length($json))+1;

	my $t = Time::HiRes::time; 
	for (1..$times) {
		$decoder->decode($json);
	}
	my $dt = Time::HiRes::time - $t;

	return $times/$dt;
}
