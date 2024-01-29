# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigFloat;

note("batan() as a class method");

cmp_ok(Math::BigFloat -> batan("-inf"), "==",
       "-1.570796326794896619231321691639751442098",
       'Math::BigFloat -> batan("-inf")');

cmp_ok(Math::BigFloat -> batan("-2"), "==",
       "-1.107148717794090503017065460178537040070",
       'Math::BigFloat -> batan("-2")');

cmp_ok(Math::BigFloat -> batan(0), "==", "0",
       'Math::BigFloat -> batan(0)');

cmp_ok(Math::BigFloat -> batan("2"), "==",
       "1.107148717794090503017065460178537040070",
       'Math::BigFloat -> batan("2")');

cmp_ok(Math::BigFloat -> batan("inf"), "==",
       "1.570796326794896619231321691639751442098",
       'Math::BigFloat -> batan("inf")');

is(Math::BigFloat -> batan("NaN"), "NaN",
   'Math::BigFloat -> batan("NaN")');

note("batan() as an instance method");

cmp_ok(Math::BigFloat -> new("-inf") -> batan(), "==",
       "-1.570796326794896619231321691639751442098",
       'Math::BigFloat -> new("-inf")');

cmp_ok(Math::BigFloat -> new("-2") -> batan(), "==",
       "-1.107148717794090503017065460178537040070",
       'Math::BigFloat -> new("-2")');

cmp_ok(Math::BigFloat -> new(0) -> batan(), "==", "0",
       'Math::BigFloat -> new(0)');

cmp_ok(Math::BigFloat -> new("2") -> batan(), "==",
       "1.107148717794090503017065460178537040070",
       'Math::BigFloat -> new("2")');

cmp_ok(Math::BigFloat -> new("inf") -> batan(), "==",
       "1.570796326794896619231321691639751442098",
       'Math::BigFloat -> new("inf")');

is(Math::BigFloat -> new("NaN") -> batan(), "NaN",
   'Math::BigFloat -> new("NaN")');

################################################################################

use Math::Complex ();

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

my $class = 'Math::BigFloat';

# atan X

sub atan { atan2($_[0], 1) }

# isnan X

sub isnan { $_[0] != $_[0] }

# linspace MIN, MAX, N
#
# Returns N linearly spaced elements from MIN to MAX.

sub linspace {
    my ($xmin, $xmax, $n) = @_;

    if ($n == 0) {
        return ();
    } elsif ($n == 1) {
        return ($xmin);
    } else {
        my $c = ($xmax - $xmin) / ($n - 1);
        return map { $xmin + $c * $_  } 0 .. ($n - 1);
    }
}

# logspace MIN, MAX, N
#
# Returns N logarithmically spaced elements from MIN to MAX.

sub logspace {
    my ($xmin, $xmax, $n) = @_;
    if ($n == 0) {
        return ();
    } elsif ($n == 1) {
        return ($xmin);
    } else {
        my @lin = linspace(log($xmin), log($xmax), $n);
        my @log = map { exp } @lin;
        $log[   0   ] = $xmin;
        $log[ $#log ] = $xmax;
        return @log;
    }
}

my @x;
@x = logspace(0.01, 12, 20);
@x = map { sprintf "%.3g", $_ } @x;
@x = (reverse(map( { -$_ } @x)), 0, @x, $nan);

my $accu       = 16;
my $tol        = 1e-13;
my $max_relerr = 0;

for (my $i = 0; $i <= $#x ; ++$i) {
    my $x = $x[$i];

    my $pl = atan($x);
    my $bf = $class -> new("$x") -> batan($accu);

    my $desc = qq|$class->new("$x")->batan($accu) vs. CORE::atan2("$x", 1)|;

    if (isnan($x)) {
        is($bf, "NaN", $desc);
    } elsif ($x == 0) {
        cmp_ok($bf, '==', $pl, $desc);
    } else {
        my $relerr = abs(($bf - $pl) / $pl); # relative error
        #printf("# %23.15e %23.15e %23.15e %23.15e\n", $x, $pl, $bf, $relerr);
        cmp_ok($relerr, '<', $tol, "relative error of $desc");
        $max_relerr = $relerr if $relerr > $max_relerr;
    }
}

diag("Maximum relative error = ", $max_relerr -> numify(), "\n");

# Verify that accuracy and precision is restored (CPAN RT #150523).

{
    $class -> accuracy(10);
    is($class -> accuracy(), 10, "class accuracy is 10 before batan()");
    my $x = $class -> new("1.2345");
    $x -> batan();
    is($class -> accuracy(), 10, "class accuracy is 10 after batan()");
}

SKIP: {
    skip "Test causes accuracy and precision to be set internally. Fixme!", 2;

    $class -> precision(-10);
    is($class -> precision(), -10, "class precision is -10 before batan()");
    my $x = $class -> new("1.2345");
    $x -> batan();
    is($class -> precision(), -10, "class precision is -10 after batan()");
}

done_testing();
