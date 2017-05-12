#!/usr/bin/env perl

use strict;
use warnings;

# -----------

my $i;
my $pi = 3.14159265;
my $x;
my $y;

$x = 50;

for ($i = 0; $i <= (2 * $pi); $i += 0.5)
{
	$x = 100 + int(100 * $i);
	$y = 100 + int(100 * sin($i) );

	print "$x, $y. @{[$y + 150]}\n";
}
