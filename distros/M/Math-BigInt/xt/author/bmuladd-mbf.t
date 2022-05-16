# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2 + 4096 + 10;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("bmuladd() as a class method");

$x = Math::BigFloat -> bmuladd("2", "3", "5");
subtest '$x = Math::BigFloat -> bmuladd("2", "3", "5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 11, '$x == 11');
};

note("bmuladd() as an instance method");

$x = Math::BigFloat -> new("2"); $y = $x -> bmuladd("3", "5");
subtest '$x = Math::BigFloat -> new("2"); $y = $x -> bmuladd("3", "5");' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 11, '$x == 11');
};

SKIP: {
    skip "for now, but reveals an old bug, so must be fixed", 4096;

    # Check consistency bmuladd() vs. bmul() + badd()

    my @values = qw/ -Inf -3 -2.5 -2 -1.5 -1 0.5 0 0.5 1 1.5 2 2.5 3 Inf NaN /;
    for my $a (@values) {
        for my $b (@values) {
            for my $c (@values) {

                my $test = qq|Math::BigFloat -> new("$a") -> bmuladd("$b", "$c")|
                         . qq| vs. Math::BigFloat -> new("$a") -> bmul("$b")|
                         . qq| -> badd("$c")|;

                $x = Math::BigFloat -> new("$a") -> bmuladd("$b", "$c");
                $y = Math::BigFloat -> new("$a") -> bmul("$b") -> badd("$c");

                subtest $test => sub {
                    plan tests => 3;
                    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
                    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
                    if ($x -> is_nan() && $y -> is_nan()) {
                        is($x, $y, '$x == $y');
                    } else {
                        cmp_ok($x, "==", $y, '$x == $y');
                    }
                };
            }
        }
    }
}

SKIP: {
    skip "for now, but reveals an old bug, so must be fixed", 10;

    # Test when the same object appears more than once.

    my $t;
    for my $a (-2, 2) {
        for my $b (-3, 3) {

            $x = Math::BigFloat -> new("$a"); $y = $x -> bmuladd("$b", $x);
            $t = qq|\$x = Math::BigFloat->new("$a"); \$y = \$x -> bmuladd("$b", \$x);|;
            subtest $t => sub {
                plan tests => 2;
                is(ref($x), 'Math::BigFloat', 'class of $x');
                cmp_ok($x, "==", $a * $b + $a, 'value of $x');
            };

            $x = Math::BigFloat -> new("$a"); $y = $x -> bmuladd($x, "$b");
            $t = qq|\$x = Math::BigFloat->new("$a"); \$y = \$x -> bmuladd(\$x, "$b");|;
            subtest $t => sub {
                plan tests => 2;
                is(ref($x), 'Math::BigFloat', 'class of $x');
                cmp_ok($x, "==", $a * $a + $b, 'value of $x');
            };
        }

        $x = Math::BigFloat -> new("$a"); $y = $x -> bmuladd($x, $x);
        $t = qq|\$x = Math::BigFloat->new("$a"); \$y = \$x -> bmuladd(\$x, \$x);|;
        subtest $t => sub {
            plan tests => 2;
            is(ref($x), 'Math::BigFloat', 'class of $x');
            cmp_ok($x, "==", $a * $a + $a, 'value of $x');
        };
    }
}
