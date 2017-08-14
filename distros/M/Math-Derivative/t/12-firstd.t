#!perl -T
use 5.008003;
use strict;
use warnings FATAL => 'all';
use Math::Derivative qw(Derivative1);
use Math::Utils qw(:compare);
use Test::More tests => 1;


my($fltcmp) = generate_fltcmp();

my @xvals = (
	1 .. 7);
my @yvals = (
	0.5, 0.6, 0.8, 1.0, 1.4, 1.5, 2.0);

my @expected = (
	0.1, 0.15, 0.2, 0.3, 0.25, 0.3, 0.5);

my @first_d = Derivative1(\@xvals, \@yvals);

my $msg = "";

for my $j (0 .. $#expected)
{
	if (&$fltcmp($first_d[$j], $expected[$j]) != 0)
	{
		$msg .= sprintf("%g returned at index %d; expected %g\n",
				$first_d[$j],
				$j,
				$expected[$j]);
	}
}

if ($#expected < $#first_d)
{
	$msg .= "More values returned than expected: (" .
		join(", ", @first_d[$#expected+1 .. $#first_d]) . ")\n";
}

ok($msg eq "", $msg);

