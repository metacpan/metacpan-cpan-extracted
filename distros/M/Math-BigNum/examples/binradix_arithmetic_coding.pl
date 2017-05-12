#!/usr/bin/perl

#
## The arithmetic coding algorithm (radix+binary)
#

# See: http://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum;

sub cumulative_freq {
    my ($freq) = @_;

    my %cf;
    my $total = Math::BigNum->new(0);
    foreach my $c (sort keys %$freq) {
        $cf{$c} = $total;
        $total += $freq->{$c};
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

    # Limit and base
    my $base = scalar @chars;

    # Lower bound
    my $L = Math::BigNum->new(0);

    # Product of all frequencies
    my $pf = Math::BigNum->new(1);

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    for my $c (@chars) {
        $L->bmul($base)->badd($cf{$c} * $pf);
        $pf->bmul($freq{$c});
    }

    # Upper bound
    my $U = $L + $pf;

    my $len = $L->length;

    $L = Math::BigNum->new("$L / " . Math::BigNum->new(10)->bpow($len));
    $U = Math::BigNum->new("$U / " . Math::BigNum->new(10)->bpow($len));

    my $big_two = Math::BigNum->new(2);
    my $two_pow = Math::BigNum->new(1);
    my $n       = Math::BigNum->new(0);

    my $bin = '';
    while ($n < $L || $n >= $U) {
        my $m = $two_pow->bmul($big_two)->inv;

        if ($n + $m < $U) {
            $n += $m;
            $bin .= '1';
        }
        else {
            $bin .= '0';
        }
    }

    #~ say $L;
    #~ say $U;

    return ($bin, $len, \%freq);
}

sub arithmethic_decoding {
    my ($enc, $pow, $freq) = @_;

    my $two_pow = Math::BigNum->new(1);
    my $big_two = Math::BigNum->new(2);

    my $line = Math::BigNum->new(0);

    my @bin = split(//, $enc);
    foreach my $i (0 .. $#bin) {
        $line->badd(Math::BigNum->new($bin[$i])->bdiv($two_pow->bmul($big_two)));
    }

    $enc = $line->bmul(Math::BigNum->new(10)->bpow($pow))->bint;

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
    for (my $i = $base - 1 ; $i >= 0 ; $i--) {

        my $pow = $base**$i;
        my $div = $enc->idiv($pow);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        my $rem = ($enc - $pow * $cv) / $fv;

        #~ say "$enc / $base^$i = $div ($c)";
        #~ say "($enc - $base^$i * $cv) / $fv = $rem\n";

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
