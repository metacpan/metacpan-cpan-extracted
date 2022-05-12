#!/usr/bin/env perl

use strict;
use warnings;

use Time::HiRes;
use Math::DCT qw(:all);

print "** Fast 2D DCT-II (Arai et al.) **\n";
bench_dct(2000000, 8);
print "** Fast 2D DCT-II (Lee) **\n";
bench_dct(100000, 32);
bench_dct(20000, 64);
bench_dct(1000, 256);
print "** Generic 2D DCT-II **\n";
bench_dct(200000, 24);
bench_dct(20000, 48);
print "** Generic 2D iDCT **\n";
bench_dct(1000000, 8, 1);
bench_dct(20000, 32, 1);

sub bench_dct {
    my $iter = shift;
    my $sz   = shift;
    my $idct = shift || 0;
    my @arrays;
    my $dct;
    my $dct_func = {'0' => \&dct2d, '1' => \&idct2d};
    push @arrays, [map { rand(256) } ( 1..$sz*$sz )] foreach 1..10;

    my $start = Time::HiRes::time();
    $dct = $dct_func->{$idct}->($arrays[$iter % 10], $sz) foreach 1..$iter;
    my $rate = int($iter/(Time::HiRes::time() - $start));

    print "${sz}x${sz}: $rate/s\n";
}