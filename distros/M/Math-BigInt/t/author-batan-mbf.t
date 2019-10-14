#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 42;

use Math::Complex ();

use Math::BigFloat;

my $inf = Math::Complex::Inf(); # most portable way to get infinity
my $nan = $inf - $inf;

my $class = 'Math::BigFloat';

# atan X

sub atan { atan2($_[0], 1) }

# isnan X

#sub isnan { !defined($_[0] <=> 0) }
sub isnan { !($_[0] <= 0 || $_[0] > 0) }

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
my $tol        = 1e-14;
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
