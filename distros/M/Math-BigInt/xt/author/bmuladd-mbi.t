# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 1012;
use Scalar::Util qw< refaddr >;

use Math::BigInt;

my ($x, $y);

note("bmuladd() as a class method");

$x = Math::BigInt -> bmuladd("2", "3", "5");
subtest '$x = Math::BigInt -> bmuladd("2", "3", "5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 11, '$x == 11');
};

note("bmuladd() as an instance method");

$x = Math::BigInt -> new("2"); $y = $x -> bmuladd("3", "5");
subtest '$x = Math::BigInt -> new("2"); $y = $x -> bmuladd("3", "5");' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 11, '$x == 11');
};

# Check consistency of bmuladd() vs. bmul() + badd()

my @values = qw/ -Inf -3 -2 -1 0 1 2 3 Inf NaN /;
for my $a (@values) {
    for my $b (@values) {
        for my $c (@values) {

            my $test = qq|Math::BigInt -> new("$a") -> bmuladd("$b", "$c")|
                     . qq| vs. Math::BigInt -> new("$a") -> bmul("$b")|
                     . qq| -> badd("$c")|;

            $x = Math::BigInt -> new("$a") -> bmuladd("$b", "$c");
            $y = Math::BigInt -> new("$a") -> bmul("$b") -> badd("$c");

            subtest $test => sub {
                plan tests => 3;
                is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
                is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
                if ($x -> is_nan() && $y -> is_nan()) {
                    is($x, $y, '$x == $y');
                } else {
                    cmp_ok($x, "==", $y, '$x == $y');
                }
            };
        }
    }
}

# Test when the same object appears more than once.

my $t;
for my $a (-2, 2) {
    for my $b (-3, 3) {

        $x = Math::BigInt -> new("$a"); $y = $x -> bmuladd("$b", $x);
        $t = qq|\$x = Math::BigInt->new("$a"); \$y = \$x -> bmuladd("$b", \$x);|;
        subtest $t => sub {
            plan tests => 2;
            is(ref($x), 'Math::BigInt', 'class of $x');
            cmp_ok($x, "==", $a * $b + $a, 'value of $x');
        };

        $x = Math::BigInt -> new("$a"); $y = $x -> bmuladd($x, "$b");
        $t = qq|\$x = Math::BigInt->new("$a"); \$y = \$x -> bmuladd(\$x, "$b");|;
        subtest $t => sub {
            plan tests => 2;
            is(ref($x), 'Math::BigInt', 'class of $x');
            cmp_ok($x, "==", $a * $a + $b, 'value of $x');
        };
    }

    $x = Math::BigInt -> new("$a"); $y = $x -> bmuladd($x, $x);
    $t = qq|\$x = Math::BigInt->new("$a"); \$y = \$x -> bmuladd(\$x, \$x);|;
    subtest $t => sub {
        plan tests => 2;
        is(ref($x), 'Math::BigInt', 'class of $x');
        cmp_ok($x, "==", $a * $a + $a, 'value of $x');
    };
}
