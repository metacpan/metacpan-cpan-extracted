#!perl -T
use 5.008003;
use strict;
use warnings FATAL => 'all';
use Math::Derivative qw(Derivative1);
use Math::Utils qw(:compare);
use Test::More tests => 1;


my($fltcmp) = generate_fltcmp();

my @xvals = (
	2.3, 2.4, 2.5, 2.6, 2.7);
my @yvals = (
	2.0, 2.1, 3.0, 4.0, 4.2);

my @expected = (
	1.0, 5.0, 9.5, 6.0, 2.0);

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

