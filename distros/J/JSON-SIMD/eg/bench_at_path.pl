#!/usr/bin/perl

use strict;
use warnings;
use feature qw/say/;
use JSON::SIMD;
use Time::HiRes;
use File::Basename;
use FindBin qw/$Bin/;

my $fn = "$Bin/twitter.json";
my $json;
{
	local $/;
	open my $F, '<', $fn or die "Can't open $fn";
	$json = <$F>;
	close $F;
}



printf "%10s %10s %6s\n", qw/decode at_pointer diff%/;
say '-' x 60;
my $orig       = run(0, $json);
my $at_pointer = run(1, $json);
my $diff = 100 * ($at_pointer - $orig) / $orig;
printf "%10.2f %10.2f %6.2f\n", $orig, $at_pointer, $diff;


sub run {
	my ($at_pointer, $json, $times) = @_;
	$times //= 10;

	my $decoder = JSON::SIMD->new->utf8->use_simdjson;
	my $dt;
	if ($at_pointer) {
		my $t = Time::HiRes::time; 
		for (1..$times) {
			$decoder->decode_at_pointer($json, '/statuses/55/user/entities/description/urls');
		}
		$dt = Time::HiRes::time - $t;
	} else {
		my $t = Time::HiRes::time; 
		for (1..$times) {
			$decoder->decode($json);
		}
		$dt = Time::HiRes::time - $t;
	}
	return $times/$dt;
}
