# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 19-scale.t'
use 5.010001;
use Test::More tests => 14;

use Math::Utils qw(:utility :compare);
use strict;
use warnings;

my $fltcmp = generate_fltcmp(1e-7);

#
# Cut a range by half (just random examples);
# Kelvin to Centigrade (melting points of gold, silver, and copper);
# and arithmetic RGB to 8-bit RGB (before rounding them to integers).
# 
my @trials = (
	[ [0, 100], [0, 50], [10, 25, 37, 49, 50], [5, 12.5, 18.5, 24.5, 25] ],
	[ [0, 2000], [-273.15, 1726.85], [1337.33, 1234.93, 1357.77], [1064.18, 961.78, 1084.62] ],
	[ [0, 1], [0, 256], [0.93, 0.42, 0.33], [238.08, 107.52, 84.48] ],
);

for my $t (@trials)
{
	my @case = @$t;
	my @scale0 = @{$case[0]};
	my @scale1 = @{$case[1]};
	my @value0 = @{$case[2]};
	my @value1 = @{$case[3]};
	my @scale_v = uniform_scaling(\@scale0, \@scale1, \@value0);

	for my $idx (0 .. $#scale_v)
	{
		ok( (&$fltcmp($scale_v[$idx], $value1[$idx]) == 0),
			"   " . $value0[$idx] . " to " . $value1[$idx] . " returned" . $scale_v[$idx] . "\n"
		);
	}
}

#
# 8-bit RGB to arithmetic RGB (before rounding to two decimal places).
#
my @trials01 = (
	[ [0, 256], [238, 108, 84], [0.9296875, 0.421875, 0.328125] ],
);

for my $t (@trials01)
{
	my @case = @$t;
	my @scale0 = @{$case[0]};
	my @value0 = @{$case[1]};
	my @value1 = @{$case[2]};
	my @scale_v = uniform_01scaling(\@scale0, \@value0);

	for my $idx (0 .. $#scale_v)
	{
		ok( (&$fltcmp($scale_v[$idx], $value1[$idx]) == 0),
			"   " . $value0[$idx] . " to " . $value1[$idx] . " returned" . $scale_v[$idx] . "\n"
		);
	}
}


1;
