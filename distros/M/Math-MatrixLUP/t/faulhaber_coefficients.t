#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Math::AnyNum };
    plan skip_all => "Math::AnyNum is not installed"
      if $@;
    plan skip_all => "Math::AnyNum >= 0.38 is needed"
      if ($Math::AnyNum::VERSION < 0.38);
}

plan tests => 5;

use Math::MatrixLUP;
use Math::AnyNum qw(:overload ipow sum);

sub faulhaber_coefficients {
    my ($n) = @_;

    my @acc = (0, 1);

    foreach my $k (1 .. $n + 1) {
        $acc[$k] = $acc[$k - 1] + ipow($k, $n);
    }

    # Build a Vandermonde matrix
    my $A = Math::MatrixLUP->build(
        $n + 2,
        sub {
            my ($i, $j) = @_;
            ipow($i, $j);
        }
    );

    $A->solve(\@acc);
}

is(join(', ', @{faulhaber_coefficients(0)}), "0, 1");
is(join(', ', @{faulhaber_coefficients(1)}), "0, 1/2, 1/2");
is(join(', ', @{faulhaber_coefficients(2)}), "0, 1/6, 1/2, 1/3");
is(join(', ', @{faulhaber_coefficients(3)}), "0, 0, 1/4, 1/2, 1/4");

my $n = 100;
my @F = @{faulhaber_coefficients(17)};

is(sum(map { ipow($n, $_) * $F[$_] } 0 .. $#F), sum(map { ipow($_, 17) } 1 .. $n));
