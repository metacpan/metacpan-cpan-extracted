#!perl -T
use 5.008003;
use strict;
use warnings FATAL => 'all';
use Math::Derivative qw(Derivative1);
use Math::Utils qw(:compare);
use Test::More tests => 1;


my($fltcmp) = generate_fltcmp();

my @xvals = (
	1.5, 1.6, 1.9, 2.0, 2.3, 2.4);
my @yvals = (
	11.0, 11.7, 12.5, 12.7, 13.0, 13.1);

my @expected = (
	7, 3.75, 2.5, 1.25, 1.0, 1.0);

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

