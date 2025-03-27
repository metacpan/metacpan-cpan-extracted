# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 9012;
use Scalar::Util qw< refaddr >;

use Math::Complex;
use Math::BigInt;

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

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
subtest '$x = Math::BigInt -> new("2"); $y = $x -> bmuladd("3", "5");'
  => sub {
      plan tests => 4;
      is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
      is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
      is(refaddr($x), refaddr($y), '$x and $y are the same object');
      cmp_ok($x, "==", 11, '$x == 11');
  };

note <<'EOF';

Verify that these three expressions give the same result:

    $x -> bmuladd($y, $z)
    $x -> bmul($y) -> badd($z)
    $x * $y + $z
EOF

my @values = qw< -Inf -3 -2 -1 0 1 2 3 Inf NaN >;
for my $a (@values) {
    for my $b (@values) {
        for my $c (@values) {

            note <<"EOF";

\$x = Math::BigInt -> new("$a") -> bmuladd("$b", "$c");
\$y = Math::BigInt -> new("$a") -> bmul("$b") -> badd("$c");
\$z = $a * $b + $c;

EOF

            my $x = Math::BigInt -> new("$a") -> bmuladd("$b", "$c");
            my $y = Math::BigInt -> new("$a") -> bmul("$b") -> badd("$c");

            my $z = $a * $b + $c;

            $z = "NaN" if $z =~ /nan/i;
            if ($z =~ /inf/i) {
                $z = $z < 0 ? "-inf" : "inf";
            }

            subtest "$a * $b + $c = $z" => sub {
                plan tests => 4;

                is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
                is($x, $z, qq|Math::BigInt -> new("$a") -> bmuladd("$b", "$c")|);

                is(ref($y), 'Math::BigInt', '$x is a Math::BigInt');
                is($y, $z, qq|Math::BigInt -> new("$a") -> bmul("$b") -> badd("$c")|);
            };
        }
    }
}

note <<'EOF';

Test when the same object appears more than once.

EOF

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

# Some random tests.

for (1 .. 20) {
    for (1 .. 20) {
        for (1 .. 20) {

            my $x = int(rand(2 ** int(rand(24))));
            $x = -$x if rand() < 0.5;
            $x = Math::BigInt -> new($x);

            my $y = int(rand(2 ** int(rand(24))));
            $y = -$y if rand() < 0.5;
            $y = Math::BigInt -> new($y);
            my $y_orig = $y -> copy();

            my $z = int(rand(2 ** int(rand(24))));
            $z = -$z if rand() < 0.5;
            $z = Math::BigInt -> new($z);
            my $z_orig = $z -> copy();

            note <<"EOF";

\$w1 = Math::BigInt -> new("$x") -> bmuladd("$y", "$z");
\$w2 = Math::BigInt -> new("$x") -> bmul("$y") -> badd("$z");

EOF

            my $w1 = $x -> copy() -> bmul($y -> copy()) -> badd($z -> copy());
            my $w2 = $x -> copy() -> bmuladd($y, $z);
            subtest "$x * $y + $z" => sub {
                plan tests => 3;

                is($w1, $w2, '$w1 and $w2 are identical');
                is($y, $y_orig, '$y is unmodified');
                is($z, $z_orig, '$z is unmodified');
            };
        }
    }
}
