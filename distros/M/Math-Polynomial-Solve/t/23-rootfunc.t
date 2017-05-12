#
# Tests of the poly_roots() function with both root_function on and off.
#
use 5.010001;
use Test::More tests => 34;

use Math::Polynomial::Solve qw(:numeric poly_nonzero_term_count);
use Math::Complex;
use Math::Utils qw(:compare);
use strict;
use warnings;

require "t/coef.pl";

my $fltcmp = generate_fltcmp();

my @case = (
	[1, 0, 1],
	[1, 0, 0, 1],
	[1, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, -1],
	[1, 0, 0, -1],
	[1, 0, 0, 0, -1],
	[1, 0, 0, 0, 0, -1],
	[1, 0, 0, 0, 0, 0, -1],
	[1, 0, 0, 0, 0, 0, 0, -1],
	[2, 0, 1],
	[9, 0, 0, 27],
	[1, 0, 0, 0, 0, 5],
	[1, 0, 1, 0, 1],	# shouldn't use root() ever.
	[3, 0, -1, -4, 2],	# shouldn't use root() ever.
);

#
# Use poly_roots() as per nomal...
#
poly_option(root_function => 0);

for (@case)
{
	my @coef = @$_;
	my $n = $#coef;
	my @x = poly_roots(@coef);
	my $cn_1 = -sumof(@x) * $coef[0];
	my $c0 = prodof(@x) * $coef[0];
	$c0 = -$c0 if ($n % 2 == 1);

	ok((&$fltcmp($cn_1, $coef[1]) == 0 and &$fltcmp($c0, $coef[$n]) == 0),
		" root_function => 0,   [ " . join(", ", @coef) . " ]");

	#print "\nmy \$cn_1 = $cn_1; \$coef[1] = ", $coef[1], "\n";
	#print "\nmy \$c0 = $c0; \$coef[$n] = ", $coef[$n], "\n";
	#print rootformat(@x), "\n\n";
}

#
# Repeat, using the root() function whenever possible.
#
poly_option(root_function => 1);

for (@case)
{
	my @coef = @$_;
	my $n = $#coef;
	my $tc = poly_nonzero_term_count(@coef);
	my @x = poly_roots(@coef);
	my $cn_1 = -sumof(@x) * $coef[0];
	my $c0 = prodof(@x) * $coef[0];
	$c0 = -$c0 if ($n % 2 == 1);


	ok((&$fltcmp($cn_1, $coef[1]) == 0 and &$fltcmp($c0, $coef[$n]) == 0),
		" root_function => 1, nz terms = $tc,   [ " . join(", ", @coef) . " ]");

	#print "\nmy \$b = $b; \$coef[1] = ", $coef[1], "\n";
	#print "\nmy \$e = $e; \$coef[$n] = ", $coef[$n], "\n";
	#print rootformat(@x), "\n\n";
}

1;

