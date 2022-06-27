# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 5;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;
use Math::BigRat;

Math::BigFloat -> upgrade("Math::BigRat");

my ($x, $y);

# bdiv()

$x = Math::BigFloat -> bdiv(3, 1);      # doesn't upgrade
subtest '$x = Math::BigFloat -> bdiv(3, 1);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 3, '$x == 3');
};

$x = Math::BigFloat -> bdiv(1, 3);      # upgrades
subtest '$x = Math::BigFloat -> bdiv(1, 3);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is($x, "1/3", '$x == 1/3');
};

# brsft()

$x = Math::BigFloat -> brsft(0, 7, 2);   # doesn't upgrade
subtest '$x = Math::BigFloat -> brsft(32, 0, 2);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 0, '$x == 0');
};

$x = Math::BigFloat -> brsft(32, 0, 2);   # doesn't upgrade
subtest '$x = Math::BigFloat -> brsft(32, 0, 2);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 32, '$x == 32');
};

$x = Math::BigFloat -> brsft(32, 7, 2);   # upgrades
subtest '$x = Math::BigFloat -> brsft(32, 7, 2);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is($x, "1/4", '$x == 1/4');
};
