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
        fixed_point => sub { $num1 <=> -1.999 },
        bigfloat    => sub { $num2 <=> -1.999 },
        perl_float  => sub { $num3 <=> -1.999 },
    }
);

cmpthese(
    100_000,
    {
        fixed_point => sub { $num1 <=> -1.999 },
        bigfloat    => sub { $num2 <=> -1.999 },
        perl_float  => sub { $num3 <=> -1.999 },
    }
);
