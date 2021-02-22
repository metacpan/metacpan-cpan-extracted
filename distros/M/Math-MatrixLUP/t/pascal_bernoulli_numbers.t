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

plan tests => 7;

use Math::MatrixLUP;
use Math::AnyNum qw(:overload binomial factorial);

sub pascal_bernoulli_number {
    my ($n) = @_;

    my $A = Math::MatrixLUP->build(
        $n,
        sub {
            my ($i, $k) = @_;
            $k > $i + 1 ? 0 : binomial($i + 2, $k);
        }
    );

    $A->det / factorial($n + 1);
}

is(pascal_bernoulli_number(0), 1);
is(pascal_bernoulli_number(1), 1 / 2);
is(pascal_bernoulli_number(2), 1 / 6);
is(pascal_bernoulli_number(3), 0);
is(pascal_bernoulli_number(4), -1 / 30);
is(pascal_bernoulli_number(5), 0);
is(pascal_bernoulli_number(6), 1 / 42);
