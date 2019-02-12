#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Math::AnyNum };
    plan skip_all => "Math::AnyNum is not installed"
      if $@;
    plan skip_all => "Math::AnyNum >= 0.30 is needed"
      if ($Math::AnyNum::VERSION < 0.30);
}

plan tests => 2;

use Math::MatrixLUP;
use Math::AnyNum qw(ipow sum);

# A sequence of n numbers
my @v = (35, 85, 102, 137, 120);

# Create a new nXn Vandermonde matrix
my $A = Math::MatrixLUP->build(
    scalar(@v),
    sub {
        my ($i, $j) = @_;
        ipow($i, $j);
    }
);

my $S = $A->solve(\@v);

is(join(', ', @$S), "35, 455/4, -2339/24, 155/4, -121/24");
is(
    join(
        ', ',
        map {
            my $x = $_;
            sum(map { $x**$_ * $S->[$_] } 0 .. $#{$S})
          } 0 .. $#v
        ),
    "35, 85, 102, 137, 120"
  );
