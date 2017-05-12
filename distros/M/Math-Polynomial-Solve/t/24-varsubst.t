#
# Tests of the poly_roots() function with varsubst on and off.
#
use 5.010001;
use Test::More tests => 30;

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
	[1, 0, 2, 0, 1],
	[1, 0, 0, 0, 0, 1],
	[1, 0, 0, 2, 0, 0, 1],
	[1, 0, 1, 0, 0, 0, 1, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9],
	[2, 0, 1],
	[9, 0, 0, 27],
	[1, 0, 0, 0, 0, 5],
);

#
# Use poly_roots() as per nomal...
#
poly_option(varsubst => 0);

for (@case)
{
	my @coef = @$_;
	my $n = $#coef;
	my @x = poly_roots(@coef);
	my $cn_1 = -sumof(@x) * $coef[0];
	my $c0 = prodof(@x) * $coef[0];
	$c0 = -$c0 if ($n % 2 == 1);

	ok((&$fltcmp($cn_1, $coef[1]) == 0 and &$fltcmp($c0, $coef[$n]) == 0),
		" varsubst => 0,   [ " . join(", ", @coef) . " ]");

	#print "\nmy \$cn_1 = $cn_1; \$coef[1] = ", $coef[1], "\n";
	#print "\nmy \$c0 = $c0; \$coef[$n] = ", $coef[$n], "\n";
	#print rootformat(@x), "\n\n";
}

#
# Repeat, using variable substitution function whenever possible.
#
poly_option(varsubst => 1);

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
		" varsubst => 1, nz terms = $tc,   [ " . join(", ", @coef) . " ]");

	#print "\nmy \$b = $b; \$coef[1] = ", $coef[1], "\n";
	#print "\nmy \$e = $e; \$coef[$n] = ", $coef[$n], "\n";
	#print rootformat(@x), "\n\n";
}

#
# Repeat again, now using the classical methods after substituting.
#
poly_option(hessenberg => 0);

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
		" varsubst => 1, nz terms = $tc,   [ " . join(", ", @coef) . " ]");

	#print "\nmy \$b = $b; \$coef[1] = ", $coef[1], "\n";
	#print "\nmy \$e = $e; \$coef[$n] = ", $coef[$n], "\n";
	#print rootformat(@x), "\n\n";
}

1;

