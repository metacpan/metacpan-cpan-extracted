use Test::More tests => 5;

use Math::Brent qw(Minimise1D);
use Math::Utils qw(:compare);
use strict;
use warnings;

my($x, $y);
my $fltcmp = generate_fltcmp(5e-7);
my $brent_tol = 1e-8;

sub sinc
{
	my($x) = @_;
	return $x? sin($x)/$x: 1;
}

#
# Some simple functions. Equations 1 and 3 come from John Burkardt's
# test page at
# <http://people.sc.fsu.edu/~jburkardt/cpp_src/brent/brent_prb_output.txt>.
#
my $eqn1 = sub {my($x) = @_; return 1 + ($x - 2)**2;};
my $eqn2 = sub {my($x) = @_; return 6.25 + $x*$x*(-24 + $x*8);};
my $eqn3 = sub {my($x) = @_; return exp(-$x) + $x**2;};

($x, $y) = Minimise1D(1, 1, \&sinc, $brent_tol);
ok(&$fltcmp($y, -.217233628) == 0, "Sinc(), ($x, $y)");

($x, $y) = Minimise1D(1.5, 1.5, $eqn1);
ok(&$fltcmp($y, 1.0) == 0, "Anon sub 1, ($x, $y)");

($x, $y) = Minimise1D(3, 0.5, $eqn2);
ok(&$fltcmp($y, -25.75) == 0, "Anon sub 2, ($x, $y)");

($x, $y) = Minimise1D(0.5, 0.5, $eqn3);
ok(&$fltcmp($y, 0.827184) == 0, "Anon sub 3, ($x, $y)");

($x, $y) = Minimise1D(1, 1, \&sinc);
ok(&$fltcmp($y, -0.21723363) == 0, "sinc(), ($x, $y)");

1;
