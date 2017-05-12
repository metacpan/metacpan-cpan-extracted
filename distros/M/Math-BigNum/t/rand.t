#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

use Math::BigNum;

# rand()
{
    my $x = Math::BigNum->new(10);
    my $y = $x->rand;

    ok($y >= 0);
    ok($y <= 10);

    $y = $x->rand(12);
    ok($y >= 10);    # rand() is exclusive
    ok($y <= 12);    # but just to be sure
}

# irand()
{
    my $x = Math::BigNum->new(10);
    my $y = $x->irand;

    ok($y->is_int);
    ok($y >= 0);
    ok($y <= 10);

    $y = $x->irand(12);
    ok($y->is_int);
    ok($y >= 10);    # rand() is exclusive
    ok($y <= 12);    # but just to be sure
}
