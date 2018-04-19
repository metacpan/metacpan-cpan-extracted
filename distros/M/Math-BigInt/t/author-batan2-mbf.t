#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 3528;

use Math::Complex ();

use Math::BigFloat;

my $inf = Math::Complex::Inf();
my $nan = $inf - $inf;

my $class = 'Math::BigFloat';

# isnan X

#sub isnan { !($_[0] <= 0 || $_[0] > 0) }
sub isnan { !defined($_[0] <=> 0) }

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

for my $ply (@x) {
    for my $plx (@x) {
        my $plz = CORE::atan2($ply, $plx);

        # $y -> batan2($x) where $x is a scalar

        {
            my $y = $class -> new($ply);
            $y -> batan2($plx, $accu);

            my $desc = qq|\$y = $class->new("$ply");|
                     . qq| \$y->batan2("$plx", $accu)|
                     . qq| vs. CORE::atan2($ply, $plx)|;

            if (isnan($plz)) {
                is($y, "NaN", $desc);
            } elsif ($plz == 0) {
                cmp_ok($y, '==', $plz, $desc);
            } else {
                my $relerr = abs(($y - $plz) / $plz);
                if (!cmp_ok($relerr, '<', $tol, "relative error of $desc")) {
                    diag(sprintf("             CORE::atan2(...): %.15g\n" .
                                 "  Math::BigFloat->batan2(...): %.15g\n",
                                 $plz, $y));
                }
                $max_relerr = $relerr if $relerr > $max_relerr;
            }
        }

        # $y -> batan2($x) where $x is an object

        {
            my $x = $class -> new($plx);
            my $y = $class -> new($ply);
            $y -> batan2($plx, $accu);

            my $desc = qq|\$y = $class->new("$ply");|
                     . qq| \$x = $class->new("$plx");|
                     . qq| \$y->batan2(\$x, $accu)|
                     . qq| vs. CORE::atan2($ply, $plx)|;

            if (isnan($plz)) {
                is($y, "NaN", $desc);
            } elsif ($plz == 0) {
                cmp_ok($y, '==', $plz, $desc);
            } else {
                my $relerr = abs(($y - $plz) / $plz);
                if (!cmp_ok($relerr, '<', $tol, "relative error of $desc")) {
                    diag(sprintf("             CORE::atan2(...): %.15g\n" .
                                 "  Math::BigFloat->batan2(...): %.15g\n",
                                  $plz, $y));
                }
                $max_relerr = $relerr if $relerr > $max_relerr;
            }
        }

    }
}

diag("Maximum relative error = ", $max_relerr -> numify(), "\n");
