#!perl -T
use 5.008003;
use strict;
use warnings FATAL => 'all';
use Math::Derivative qw(forwarddiff);
use Math::Utils qw(:compare);
use Test::More tests => 1;


my($fltcmp) = generate_fltcmp();

my @temperature = (
	16.4, 16.46, 16.52,
	16.58, 16.65, 16.71,
	16.79, 16.87, 16.94 );
my @height = (
	5000.4, 5007.2, 5014.0,
	5021.7, 5029.8, 5037.9,
	5046.2, 5053.7, 5061.7);

my @expected = (
	0.008823529, 0.008823529, 0.007792208,
	0.008641975, 0.007407407, 0.009638554,
	0.010666667, 0.00875, 0.009345794);

my @first_derivative = forwarddiff(\@height, \@temperature);

my $msg = "";

for my $j (0 .. $#expected - 1)
{
	if (&$fltcmp($first_derivative[$j], $expected[$j]) != 0)
	{
		$msg .= sprintf("%g returned at index %d; expected %g\n",
				$first_derivative[$j],
				$j,
				$expected[$j]);
	}
}

ok($msg eq "", $msg);

