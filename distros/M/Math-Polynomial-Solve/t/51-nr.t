use 5.010001;
use Test::More tests => 6;

use Math::Polynomial::Solve qw(newtonraphson ascending_order);
use Math::Utils qw(:compare :polynomial);
use Math::Complex;
use strict;
use warnings;

require "t/coef.pl";

my $fltcmp = generate_fltcmp();

ascending_order(1);

ok_newton([-12, -11, 2, 1], [-4.5, 0.5, 2.5]);
ok_newton([-1, -2, 11, 12], [-0.5, 0.3, -5]);
exit(0);

sub ok_newton
{
	my($c_ref, $est_ref) = @_;
	my @coef = @$c_ref;
	my @x = newtonraphson($c_ref, $est_ref);

	#rootprint(@x);

	for my $xv (@x)
	{
		my $yv = pl_evaluate($c_ref, $xv);
		ok( (&$fltcmp($yv, 0.0) == 0),
		"   [ " . join(", ", @coef) . " ], root == $xv");
	}
}

1;
