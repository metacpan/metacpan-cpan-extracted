#! /usr/bin/perl -w

# An implementation of key sharing from

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

# l = number of bits in subkey (8, 16 or 32)
# n = number of shares

use Math::FastGF2 ":ops";
use strict;

my $random_source="/dev/random";

# random num in [0, 2 ** l)
sub randq {
    my $w=shift; $w >>= 3;
    my @num;
    my $temp = `dd if=$random_source bs=1 count=$w 2> /dev/null`;
    if ($w == 1) {
	return  scalar unpack('C',$temp);
    } elsif ($w == 2) {
	return  scalar unpack('n',$temp);
    } elsif ($w == 4) {
	return  scalar unpack('N',$temp);
    } else {
	die "Can only unpack rands of size 8, 16 or 32 bits";
    }
}

# print a hex number, high nibble first
sub hexq {
    my $w=shift;
    my $x=shift;

    return sprintf("%0*x", $w >> 2, $x);
}

sub horner {
    # Evaluate polynomial via Horner's rule.
    my ($w, $x, @coeffs) = @_;
    my $val = 0;

    foreach my $c (@coeffs) {
	$val = $c ^ gf2_mul($w, $x , $val);
    }

    return $val;
}

sub thresh {
    my ($w, $b, $k, $n) = @_;
    my $i;
    my @coeffs = ();
    # high coeff goes first
    for ($i = 1; $i < $k; $i++) {
	push(@coeffs, randq($w));
    }
    # const coeff goes last
    push(@coeffs, $b);
    my @res = ();
    for ($i = 1; $i <= $n; $i++) {
	push(@res, horner($w, $i, @coeffs));
    }
    return @res;
}

my $usage = "usage: echo KEY | $0 [-u] W K N
where
    W = width of subkeys (8, 16 or 32 bits)
    K = quorum
    N = number of shares
    0 < K <= N <= 2 ^ W

output is N lines.  Store each line separately together with a copy of
the shamir-combine.pl script.  Restore with any K of the lines fed to
shamir-combine.pl.

The width parameter specifies that the input should be broken up into
words of 8, 16 or 32 bits, and Shamir's algorithm applied to each word
independently. If W=16 or W=32 is chosen and the input is not a
multiple of 16 or 32 bits, respectively, then the message will be null
padded up to the appropriate length. Any null padding will be removed
by the shamir-combine.pl script. This may mean that an attacker has an
easier job of decrypting the final word (ie, 2 or 4 bytes) of the
message, so if the is a concern, ensure that the message to be
encrypted is a multiple of 16 or 32 bits as appropriate when using
these subkey sizes.

By default the program reads (theoretically) high-quality random
numbers from /dev/random. The -u option tells the program to use
/dev/urandom instead. Use of this option may decrease the security of
the program slightly, but it means that the program will never block
while waiting for sufficient bits of entropy to be collected by
/dev/random. See random(4) for details. This option is intended
primarily for testing, or for bulk operations where splitting many
keys quickly is more important than high security.

";

if (exists($ARGV[0]) and $ARGV[0] eq "-u") {
  shift @ARGV;
  $random_source="/dev/urandom";
}

die $usage if $#ARGV != 2;

my $w = shift @ARGV;
my $k = shift @ARGV;
my $n = shift @ARGV;

die "bad value of width: $w\n$usage" unless $w == 8 or $w == 16 or $w == 32;
die "bad value of quorum: $k\n$usage" if $k < 1 or $k > $n;
die "bad value of shares: $n\n$usage" if $n < 1 or $n > 2 ** $w;

$_ = <STDIN>;
chomp;

# zero-pad secret up to word size
while (length($_) % ($w >> 3)) {
    $_.="\0";
}

my $len = length($_) / ($w >> 3);		# number of subkeys
my @key;
if ($w == 8) {
    @key = unpack('C*',$_);
} elsif ($w == 16) {
    @key = unpack('n*',$_);
} elsif ($w == 32) {
    @key = unpack('N*',$_);
}

my @result = ();
foreach my $key (@key) {
    push(@result, thresh($w, $key, $k, $n));
}

my ($i,$j);
for ($i = 0; $i < $n; $i++) {
    printf "%d=%d=%d=", $k, $w, $i+1;
    for ($j = 0; $j < $len; $j++) {
	print hexq($w, $result[$j * $n + $i]);
    }
    print "=\n";
}
