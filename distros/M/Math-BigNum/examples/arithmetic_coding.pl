#!/usr/bin/perl

#
## The arithmetic coding algorithm.
#

# See: http://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum;

sub asciibet {
    map { chr } 0 .. 255;
}

sub cumulative_freq {
    my ($freq) = @_;

    my %cf;
    my $total = Math::BigNum->new(0);
    foreach my $c (asciibet()) {
        if (exists $freq->{$c}) {
            $cf{$c} = $total;
            $total += $freq->{$c};
        }
    }

    return %cf;
}

sub arithmethic_coding {
    my ($str) = @_;
    my @chars = split(//, $str);

    # The frequency characters
    my %freq;
    $freq{$_}++ for @chars;

    # The cumulative frequency table
    my %cf = cumulative_freq(\%freq);

    # Base
    my $base = Math::BigNum->new(scalar @chars);

    # Lower bound
    my $L = Math::BigNum->new(0);

    # Product of all frequencies
    my $pf = Math::BigNum->new(1);

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    foreach my $c (@chars) {
        $L->bmul($base)->badd($cf{$c} * $pf);
        $pf->bmul($freq{$c});
    }

    # Upper bound
    my $U = $L + $pf;

    #~ say $L;
    #~ say $U;

    my $pow = Math::BigNum->new($pf)->blog(10)->bint;
    my $enc = ($U - 1)->bidiv(Math::BigNum->new(10)->bipow($pow));

    return ($enc, $pow, \%freq);
}

sub arithmethic_decoding {
    my ($enc, $pow, $freq) = @_;

    # Multiply enc by 10^pow
    $enc *= 10**$pow;

    my $base = Math::BigNum->new(0);
    $base += $_ for values %{$freq};

    # Create the cumulative frequency table
    my %cf = cumulative_freq($freq);

    # Create the dictionary
    my %dict;
    while (my ($k, $v) = each %cf) {
        $dict{$v} = $k;
    }

    # Fill the gaps in the dictionary
    my $lchar;
    foreach my $i (0 .. $base - 1) {
        if (exists $dict{$i}) {
            $lchar = $dict{$i};
        }
        elsif (defined $lchar) {
            $dict{$i} = $lchar;
        }
    }

    # Decode the input number
    my $decoded = '';
    for (my $pow = $base**($base - 1) ; $pow > 0 ; $pow->bidiv($base)) {
        my $div = $enc->idiv($pow);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        my $rem = ($enc - $pow * $cv)->idiv($fv);

        #~ say "$enc / $base^$pow = $div ($c)";
        #~ say "($enc - $base^$pow * $cv) / $fv = $rem\n";

        $enc = $rem;
        $decoded .= $c;
    }

    # Return the decoded output
    return $decoded;
}

#
## Run some tests
#
foreach my $str (
    qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen google TOBEORNOTTOBEORTOBEORNOT),
    'In a positional numeral system the radix, or base, is numerically equal to a number of different symbols '
    . 'used to express the number. For example, in the decimal system the number of symbols is 10, namely 0, 1, 2, '
    . '3, 4, 5, 6, 7, 8, and 9. The radix is used to express any finite integer in a presumed multiplier in polynomial '
    . 'form. For example, the number 457 is actually 4×102 + 5×101 + 7×100, where base 10 is presumed but not shown explicitly.'
  ) {
    my ($enc, $pow, $freq) = arithmethic_coding($str);
    my $dec = arithmethic_decoding($enc, $pow, $freq);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}

open my $fh, '<', __FILE__;
my $content = do { local $/; <$fh> };

my ($enc, $pow, $freq) = arithmethic_coding($content);
my $dec = arithmethic_decoding($enc, $pow, $freq);

if ($dec ne $content) {
    die "Failed to encode and decode the __FILE__ correctly.";
}

say "Done!";
