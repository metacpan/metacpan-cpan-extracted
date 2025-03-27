# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2421;
use Scalar::Util qw< refaddr >;
use Math::Trig qw< Inf >;

my $class;

BEGIN { $class = 'Math::BigRat'; }
BEGIN { use_ok($class); }

my $inf = Inf;                 # (positive) infinity
my $nan = $inf - $inf;         # Not a Number

# CPAN RT #132712.

my $q1 = $class -> new("-1/2");
my ($n, $d) = $q1 -> parts();

my $n_orig = $n -> copy();
my $d_orig = $d -> copy();
my $q2 = $class -> new($n, $d);

cmp_ok($n, "==", $n_orig,
       "The value of the numerator hasn't changed");
cmp_ok($d, "==", $d_orig,
       "The value of the denominator hasn't changed");

isnt(refaddr($n), refaddr($n_orig),
     "The addresses of the numerators have changed");
isnt(refaddr($d), refaddr($d_orig),
     "The addresses of the denominators have changed");

###############################################################################

# new() as a class method:
#
# $y = $class -> new()

{
    my $y = $class -> new();
    subtest qq|\$y = $class -> new();|, => sub {
        plan tests => 2;

        is(ref($y), $class, "output arg is a $class");
        is($y, "0", 'output arg has the right value');
    };
}

# new() as an instance method:
#
# $y = $x -> new()

{
    my $x = $class -> new("999");
    my $y = $x -> new();
    subtest qq|\$x = $class -> new("999"); \$y = \$x -> new();|, => sub {
        plan tests => 3;

        is(ref($y), $class, "output arg is a $class");
        is($y, "0", 'output arg has the right value');
        isnt(refaddr($x), refaddr($y), "output is not the invocand");
    };
}

###############################################################################

# new() as a class method:
#
# $class -> new("")

{
    my $y = $class -> new("");
    subtest qq|\$y = $class -> new("");|, => sub {
        plan tests => 2;

        is(ref($y), $class, "output arg is a $class");
        is($y, "NaN", 'output arg has the right value');
   };
}

# new() as an instance method:
#
# $x -> new("")

{
    my $x = $class -> new("999");
    my $y = $x -> new("");
    subtest qq|\$x = $class -> new("999"); \$y = \$x -> new("");|, => sub {
        plan tests => 3;

        is(ref($y), $class, "output arg is a $class");
        is($y, "NaN", 'output arg has the right value');
        isnt(refaddr($x), refaddr($y), "output is not the invocand");
    };
}

###############################################################################

# new() as a class method:
#
# $class -> new(undef)

{
    my $y = $class -> new(undef);
    subtest qq|\$y = $class -> new(undef);|, => sub {
        plan tests => 2;

        is(ref($y), $class, "output arg is a $class");
        is($y, "0", 'output arg has the right value');
    };
}

# new() as an instance method
#
# $x -> new(undef)

{
    my $x = $class -> new("999");
    my $y = $x -> new(undef);
    subtest qq|\$x = $class -> new("999"); \$y = \$x -> new(undef);|, => sub {
        plan tests => 3;

        is(ref($y), $class, "output arg is a $class");
        is($y, "0", 'output arg has the right value');
        isnt(refaddr($x), refaddr($y), "output is not the invocand");
    };
}

###############################################################################
# new() as a class method with one argument
###############################################################################

# Arguments that Math::BigInt, Math::BigFloat, and Math::BigRat can handle.

my @int = qw< 1 2 5 7 inf >;
push @int, map { "-$_" } @int;
push @int, qw< 0 NaN >;

for my $int (@int) {
    for my $ref ('', 'Math::BigInt', 'Math::BigFloat', 'Math::BigRat') {
        my ($x, $y);
        my $test = '$x = ';
        $test .= $ref ? qq|$ref -> new("$int")| : qq|"$int"|;
        $test .= '; $y = Math::BigRat -> new($x);';
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        if ($int =~ /inf|nan/i) {
            is($y, $int, 'output has the right value');
        } else {
            is($y -> numify(), eval($int), 'output has the right value');
        }
    }
}

# Arguments that only Math::BigFloat and Math::BigRat can handle.

my @flt = qw< 1.2 2.6 5.25 >;
push @flt, map { "-$_" } @flt;

for my $flt (@flt) {
    for my $ref ('', 'Math::BigFloat', 'Math::BigRat') {
        my ($x, $y);
        my $test = '$x = ';
        $test .= $ref ? qq|$ref -> new("$flt")| : qq|"$flt"|;
        $test .= '; $y = Math::BigRat -> new($x);';
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        if ($flt =~ /inf|nan/i) {
            is($y, $flt, 'output has the right value');
        } else {
            is($y -> numify(), eval($flt), 'output has the right value');
        }
    }
}

# Arguments that only Math::BigRat can handle.

my @rat = qw< 3/5 7/3 13/11 >;
push @rat, map { "-$_" } @rat;

for my $rat (@rat) {
    for my $ref ('', 'Math::BigRat') {
        my ($x, $y);
        my $test = '$x = ';
        $test .= $ref ? qq|$ref -> new("$rat")| : qq|"$rat"|;
        $test .= '; $y = Math::BigRat -> new($x);';
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        if ($rat =~ /inf|nan/i) {
            is($y, $rat, 'output has the right value');
        } else {
            is($y -> numify(), eval($rat), 'output has the right value');
        }
    }
}

###############################################################################
# new() as a class method with two arguments
###############################################################################

# Arguments that Math::BigInt, Math::BigFloat, and Math::BigRat can handle.

for my $xint (@int) {
    for my $xref ('', 'Math::BigInt', 'Math::BigFloat', 'Math::BigRat') {
        for my $yint (@int) {
            for my $yref ('', 'Math::BigInt', 'Math::BigFloat', 'Math::BigRat') {
                my ($x, $y, $z);
                my $test = '$x = ';
                $test .= $xref ? qq|$xref -> new("$xint")| : qq|"$xint"|;
                $test .= '; $y = ';
                $test .= $yref ? qq|$yref -> new("$yint")| : qq|"$yint"|;
                $test .= '; $z = Math::BigRat -> new($x, $y);';

                note("\n$test\n\n");

                eval $test;
                die $@ if $@;

                my $xs = $xint eq  'inf' ?  $inf
                       : $xint eq '-inf' ? -$inf
                       : $xint eq  'NaN' ?  $nan
                       : $xint;

                my $ys = $yint eq  'inf' ?  $inf
                       : $yint eq '-inf' ? -$inf
                       : $yint eq  'NaN' ?  $nan
                       : $yint;

                my $want;
                if ($yint == 0) {
                    $want =     0 <  $xint && $xint <= $inf ?  $inf
                          : -$inf <= $xint && $xint <     0 ? -$inf
                          : $nan;
                } else {
                    $want = $xint / $yint;
                }

                is($z -> numify(), $want, 'output has the right value');
            }
        }
    }
}

###############################################################################
# Miscellaneous tests.
###############################################################################

my $cases =
  [
   [[ "000377" ], 377 ],
   [[ "03_7_7" ], 377 ],
   [[ "-03_7_7" ], -377 ],
   [[ "03_7_7e+2" ], 37700 ],
   [[ "-03_7_7e+2" ], -37700 ],
   [[ "0018", "0012" ], "3/2" ],
   [[ "001_8", "001_2" ], "3/2" ],
   [[ "001_8e2", "001_2e2" ], "3/2" ],
   [[ "0_0_1_8", "0_0_1_2" ], "3/2" ],
   [[ "0_0_1_8e2", "0_0_1_2e2" ], "3/2" ],
   [[ "000" ], "0" ],
   [[ "+000" ], "0" ],
   [[ "-000" ], "0" ],
   [[ "00e2", "000e3" ], "NaN" ],
   [[ "01e2", "000e3" ], "inf" ],
   [[ "-01e2", "000e3" ], "-inf" ],
   [[ "00e2", "001e3" ], "0" ],
   [[ "-00e2", "001e3" ], "0" ],
  ];

for my $case (@$cases) {
    my ($test, $z);
    my ($in, $want) = @$case;

    if (@$in == 1) {
        my ($x) = @$in;

        $test = qq|\$z = Math::BigRat -> new("$x");|;
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        is($z, $want, 'output has the right value');
    }

    if (@$in == 2) {
        my ($x, $y) = @$in;

        $test = qq|\$z = Math::BigRat -> new("$x", "$y");|;
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        $test = qq|\$z = Math::BigRat -> new(" $x / $y ");|;

        is($z, $want, 'output has the right value');
        note("\n$test\n\n");
        eval $test;
        die $@ if $@;
        is($z, $want, 'output has the right value');
    }
}
