use 5.010001;
use Test::More tests => 6;

use Math::Complex;
use Math::Polynomial::Solve qw(:utility);
use Math::Utils qw(:compare :polynomial);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

coefficients order => 'ascending';

ok_newton([-12, -11, 2, 1], [-4.5, 0.5, 2.5]);
ok_newton([-1, -2, 11, 12], [-0.5, 0.3, -5]);
exit(0);

sub ok_newton
{
	my($c_ref, $est_ref) = @_;
	my @coef = @$c_ref;
	my @x = newtonraphson($c_ref, $est_ref);

	for my $xv (@x)
	{
		my $yv = pl_evaluate($c_ref, $xv);
		ok( (&$eq($yv, 0.0)),
		"   [ " . join(", ", @coef) . " ], root == $xv, evaluates to $yv");
	}
}

1;
