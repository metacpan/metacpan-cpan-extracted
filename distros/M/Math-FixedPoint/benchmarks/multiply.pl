#!/usr/bin/env perl
use strict;
use warnings;
use Math::BigInt lib => 'GMP';
use Math::BigFloat;
use Benchmark qw(cmpthese);
use Math::FixedPoint;

my $num1 = Math::FixedPoint->new(1.23);
my $num2 = Math::BigFloat->new(1.23);
my $num3 = 1.23;

cmpthese(
    100_000,
    {
        fixed_point => sub { my $c = $num1; my $d = $num1 * 1.23 },
        bigfloat    => sub { my $c = $num2; my $d = $num2 * 1.23 },
        perl_float  => sub { my $c = $num3; my $d = $num3 * 1.23 },
    }
);

cmpthese(
    100_000,
    {
        fixed_point => sub { my $c = $num1; my $d = $num1 * $num1 },
        bigfloat    => sub { my $c = $num2; my $d = $num2 * $num2 },
        perl_float  => sub { my $c = $num3; my $d = $num3 * $num3 },
    }
);

cmpthese(
    100_000,
    {
        fixed_point => sub { my $c = $num1; $c *= 1 },
        bigfloat    => sub { my $c = $num2; $c *= 1 },
        perl_float  => sub { my $c = $num3; $c *= 1 },
    }
);

cmpthese(
    100_000,
    {
        fixed_point => sub { my $c = $num1; $c *= $num1 },
        bigfloat    => sub { my $c = $num2; $c *= $num2 },
        perl_float  => sub { my $c = $num3; $c *= $num3 },
    }
);

