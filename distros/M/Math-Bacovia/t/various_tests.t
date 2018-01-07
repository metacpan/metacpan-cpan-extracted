#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

use Math::Bacovia qw(:all);

plan tests => 15;

my $n = Symbol('n');

is((Power($n, 3) * Power($n, 4))->simple->pretty, 'n^7');
is((Power($n, 3) / Power($n, 4))->simple->pretty, 'n^-1');
is((Power($n, 3) * Power(42, 4))->simple->pretty, '(n^3 * 42^4)');
is((Power($n, 3) / Power(42, 4))->simple->pretty, '(n^3/42^4)');

is(Sum(0, 0, 2, 3)->pretty, '(2 + 3)');
is(Sum()->simple->pretty, '0');
is(Sum()->pretty,         '(0)');

is(Sum(3, Sum(4, 5), 6)->pretty, '(3 + 6 + 4 + 5)');
is(Sum(Sum(3, 4))->pretty, '(3 + 4)');

is(Product()->pretty, '(1)');
is(Product(1, 1, 2, 3)->pretty, '(2 * 3)');
is(Product()->simple->pretty, '1');

is(Product(3, Product(4, 5), 6)->pretty, '(3 * 6 * 4 * 5)');
is(Product(Product(3, 4))->pretty, '(3 * 4)');

{
    my $expr = (
              Fraction(1, 24) * pi * (
                  2 * pi *
                    (Log(-1 - i) + Log(-1 + i) + Log(Fraction(1, 3) - Fraction(i, 3)) + Log(Fraction(1, 3) + Fraction(i, 3))) -
                    3 * i *
                    (Log(Fraction(2, 3) - Fraction(2 * i, 3))**2 - Log(Fraction(2, 3) + Fraction(2 * i, 3))**2)
              )
    );

    # This expression can actually be simplified to:
    #   -1/48 * (log(-1)/i)^2 * log(18)

    is($expr->simple->simple->pretty,
        '((((-2/24) * log(-1) * log((36/81))) - ((0.125 * log(((6-6i)/9))^2) - (0.125 * log(((6+6i)/9))^2))) * log(-1))');
}
