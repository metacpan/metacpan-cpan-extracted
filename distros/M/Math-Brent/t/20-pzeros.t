use Test::More tests => 8;

use Math::Brent qw(Brentzero);
use Math::Utils qw(:compare :polynomial);
use strict;
use warnings;

my $fltcmp = generate_fltcmp(5e-7);
my $brent_tol = 1e-8;
my $r;

#
# Some simple polynomials.
#
my $eqn1 = sub {my($x) = @_; return pl_evaluate([-12, -11, 2, 1], $x);};
my $eqn2 = sub {my($x) = @_; return pl_evaluate([-1, -2, 11, 12], $x);};
my $eqn3 = sub {my($x) = @_; return pl_evaluate([11, 10, 8, 5, 1], $x);};

#
# Roots of the cubic eqn1.
#
$r = Brentzero(1, 5, $eqn1);
ok(&$fltcmp($r, 3.0) == 0, "Anon sub 1, claimed first zero at $r");

$r = Brentzero(-2, 0, $eqn1);
ok(&$fltcmp($r, -1.0) == 0, "Anon sub 1, claimed second zero at $r");

$r = Brentzero(-5, -3.5, $eqn1);
ok(&$fltcmp($r, -4.0) == 0, "Anon sub 1, claimed third zero at $r");

#
# Roots of the cubic eqn2.
#
$r = Brentzero(0.0, 0.5, $eqn2);
ok(&$fltcmp($r, 0.33333333) == 0, "Anon sub 2, claimed first zero at $r");

$r = Brentzero(-0.75, 0.25, $eqn2);
ok(&$fltcmp($r, -0.25) == 0, "Anon sub 2, claimed second zero at $r");

$r = Brentzero(-3, -0.5, $eqn2);
ok(&$fltcmp($r, -1) == 0, "Anon sub 2, claimed third zero at $r");

#
# First root of eqn3...
#
$r = Brentzero(-5, -2, $eqn3);
ok(&$fltcmp($r, -3.08054627) == 0, "Anon sub 3, claimed first zero at $r");

#
# ... and now its second root (the other two are complex).
#
$r = Brentzero(-2, 0, $eqn3);
ok(&$fltcmp($r, -1.83993267) == 0, "Anon sub 3, claimed second zero at $r");

1;
