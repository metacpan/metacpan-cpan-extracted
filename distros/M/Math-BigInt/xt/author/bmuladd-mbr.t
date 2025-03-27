# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12108;
use Scalar::Util qw< refaddr >;

use Math::Complex;
use Math::BigRat;

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

my ($x, $y);

note("bmuladd() as a class method");

$x = Math::BigRat -> bmuladd("2", "3", "5");
subtest '$x = Math::BigRat -> bmuladd("2", "3", "5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", 11, '$x == 11');
};

note("bmuladd() as an instance method");

$x = Math::BigRat -> new("2"); $y = $x -> bmuladd("3", "5");
subtest '$x = Math::BigRat -> new("2"); $y = $x -> bmuladd("3", "5");'
  => sub {
      plan tests => 4;
      is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
      is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
      is(refaddr($x), refaddr($y), '$x and $y are the same object');
      cmp_ok($x, "==", 11, '$x == 11');
  };

note <<'EOF';

Verify that these three expressions give the same result:

    $x -> bmuladd($y, $z)
    $x -> bmul($y) -> badd($z)
    $x * $y + $z
EOF

my @values = qw< -Inf -3 -5/2 -2 -3/2 -1 1/2 0 1/2 1 3/2 2 5/2 3 Inf NaN >;
for my $a (@values) {
    for my $b (@values) {
        for my $c (@values) {

            note <<"EOF";

\$x = Math::BigRat -> new("$a") -> bmuladd("$b", "$c");
\$y = Math::BigRat -> new("$a") -> bmul("$b") -> badd("$c");
\$z = $a * $b + $c;

EOF

            my $x = Math::BigRat -> new("$a") -> bmuladd("$b", "$c");
            my $y = Math::BigRat -> new("$a") -> bmul("$b") -> badd("$c");

            for ($a, $b, $c) {
                $_ = eval $_ if m|/|;           # 3/2 -> 1.5 etc.
            }

            my $z = $a * $b + $c;

            $z = "NaN" if $z =~ /nan/i;
            if ($z =~ /inf/i) {
                $z = $z < 0 ? "-inf" : "inf";
            }

            subtest "$a * $b + $c = $z" => sub {
                plan tests => 4;

                is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');

                $x = eval $x if $x =~ m|/|;     # 3/2 -> 1.5 etc.
                is($x, $z,
                   qq|Math::BigRat -> new("$a") -> bmuladd("$b", "$c")|);

                is(ref($y), 'Math::BigRat', '$x is a Math::BigRat');

                $y = eval $y if $y =~ m|/|;     # 3/2 -> 1.5 etc.
                is($y, $z,
                   qq|Math::BigRat -> new("$a") -> bmul("$b") -> badd("$c")|);
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

        $x = Math::BigRat -> new("$a");
        $y = $x -> bmuladd("$b", $x);
        $t = qq|\$x = Math::BigRat->new("$a"); \$y = \$x -> bmuladd("$b", \$x);|;
        subtest $t => sub {
            plan tests => 2;
            is(ref($x), 'Math::BigRat', 'class of $x');
            cmp_ok($x, "==", $a * $b + $a, 'value of $x');
        };

        $x = Math::BigRat -> new("$a");
        $y = $x -> bmuladd($x, "$b");
        $t = qq|\$x = Math::BigRat->new("$a"); \$y = \$x -> bmuladd(\$x, "$b");|;
        subtest $t => sub {
            plan tests => 2;
            is(ref($x), 'Math::BigRat', 'class of $x');
            cmp_ok($x, "==", $a * $a + $b, 'value of $x');
        };
    }

    $x = Math::BigRat -> new("$a");
    $y = $x -> bmuladd($x, $x);
    $t = qq|\$x = Math::BigRat->new("$a"); \$y = \$x -> bmuladd(\$x, \$x);|;
    subtest $t => sub {
        plan tests => 2;
        is(ref($x), 'Math::BigRat', 'class of $x');
        cmp_ok($x, "==", $a * $a + $a, 'value of $x');
    };
}

# Some random tests.

for (1 .. 20) {
    for (1 .. 20) {
        for (1 .. 20) {

            my $xn = int(rand(2 ** int(rand(24))));
            my $xd = int(rand(2 ** int(rand(24))));
            $xn = -$xn if rand() < 0.5;
            my $x = Math::BigRat -> new($xn, $xd);

            my $yn = int(rand(2 ** int(rand(24))));
            my $yd = int(rand(2 ** int(rand(24))));
            $yn = -$yn if rand() < 0.5;
            my $y = Math::BigRat -> new($yn, $yd);
            my $y_orig = $y -> copy();

            my $zn = int(rand(2 ** int(rand(24))));
            my $zd = int(rand(2 ** int(rand(24))));
            $zn = -$zn if rand() < 0.5;
            my $z = Math::BigRat -> new($zn, $zd);
            my $z_orig = $z -> copy();

            note <<"EOF";

\$w1 = Math::BigRat -> new("$x") -> bmuladd("$y", "$z");
\$w2 = Math::BigRat -> new("$x") -> bmul("$y") -> badd("$z");

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
