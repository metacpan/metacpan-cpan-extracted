#! /usr/bin/perl -w

# An implementation of key reconstruction from

# Shamir A.,
# How to Share a Secret,
# Communications of the ACM, 22, 1979, pp. 612--613.

# Original implementation written by Charles Karney
# <charles@karney.com> in 2001 and licensed under the GPL.  For more
# information, see http://charles.karney.info/misc/secret.html

# This implementation is a modification of the original, and was
# written by Declan Malone in 2009. It is also licensed under the
# GPL. This version re-implements the original algorithm to Galois
# fields, as implemented by the Math::FastGF2 module, instead of the
# original integer field mod 257. For more information, see
# https://sourceforge.net/projects/gnetraid/develop

use Math::FastGF2 ":ops";
use strict;

# l = number of bits in subkey (8, 16 or 32)
# n = number of shares


my $count = 0;
my ($quorum, $width, $keylen);
my @shx = ();
my @shy = ();
my $usage = "usage: $0
share1
share2
...
";

die "$usage" if $#ARGV != -1;

while (<STDIN>) {
    chomp;
    my ($k, $w, $j, $sh) = split(/=/);
    my $t;

    if ($count == 0) {
	$quorum = $k;
	$width = $w;
	$keylen = length($sh);
	die "bad security level"       if $w != 8 and $w != 16 and $w != 32;
	die "bad share length"         if $keylen % ($w / 4) != 0;
	die "bad quorum value $quorum" if $quorum < 1 or $quorum > 2 ** $w;
	die "Share is not a hex value" unless $sh =~ /^[0-9a-fA-F]+$/;
    } else {
	die "mismatched width $w" if $w != $width;
	die "mismatched quorum $k" if $k != $quorum;
	die "mismatched key lengths" if $keylen != length($sh);
    }
    $count++;
    die "bad share index $j" if $j < 1 or $j > 2 ** $width;
    if ($count > $quorum) {
	print "Ignoring share $j...\n";
	next;
    }
    push @shx, $j;
    while ($t = substr $sh, 0, $width >> 2, "") {
	push @shy, hex $t;
    }
}

die "$usage" if $count == 0;
die "too few shares" if $count < $quorum;
$keylen /= ($width >> 2);

my @shcoef = ();
# Calculate common coefficients
for (my $j = 0; $j < $quorum; $j++) {
    my $temp = 1;
    for (my $l = 0; $l < $quorum; $l++) {
	if ($l != $j) {
	    $temp = gf2_mul($width, $temp, $shx[$l]);
	    $temp = gf2_div($width, $temp, $shx[$j] ^ $shx[$l]);
	}
    }
    die "repeated share" if ($temp == 0);
    push @shcoef, $temp;
}

my @ans = ();
for (my $i = 0; $i < $keylen; $i++) {
    my $temp = 0;
    for (my $j = 0; $j < $quorum; $j++) {
	$temp ^= gf2_mul($width, $shy[$keylen * $j + $i], $shcoef[$j]);
    }
    if ($width == 8) {
	push @ans, chr $temp;
    } elsif ($width == 16) {
	push @ans, pack "n", $temp;
    } elsif ($width == 32) {
	push @ans, pack "N", $temp;
    }
}
my $ans= join("", @ans);
$ans =~ s/\0*$//;
print "$ans\n";
