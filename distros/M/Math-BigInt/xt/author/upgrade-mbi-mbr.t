# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 5;
use Scalar::Util qw< refaddr >;

use Math::BigInt;
use Math::BigRat;

Math::BigInt -> upgrade("Math::BigRat");

my ($x, $y);

# new()

$x = Math::BigInt -> new("2");          # doesn't upgrade
subtest '$x = Math::BigInt -> new("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

$x = Math::BigInt -> new("2.5");        # upgrades
subtest '$x = Math::BigInt -> new("2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", "5/2", '$x == 5/2');
};

# brsft()

$x = Math::BigInt -> brsft(0, 7, 2);   # doesn't upgrade
subtest '$x = Math::BigInt -> brsft(0, 7, 2);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 0, '$x == 0');
};

$x = Math::BigInt -> brsft(32, 0, 2);   # doesn't upgrade
subtest '$x = Math::BigInt -> brsft(32, 0, 2);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 32, '$x == 32');
};

$x = Math::BigInt -> brsft(32, 7, 2);   # doesn't upgrade
subtest '$x = Math::BigInt -> brsft(32, 7, 2);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is($x, "1/4", '$x == 1/4');
};
