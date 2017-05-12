#!perl -w
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>1;
use strict;
use warnings;

# As per Mike's example
# my ($x) = symbols(x);
# my $y = ($x*2 + 5*$x + 6) / ($x + 3);

my ($x) = symbols(qw(x));                # Quote the x
my $y += ($x**2 + 5*$x + 6) / ($x + 3);  # ** not *, note +=
print "$y\n";                            # Print result

my $z += ($x**8 - 1)/($x-1);             # Additional example, again note +=
print "$z\n";                            # Print result

$y = sin($x);
print $y, "\n";

use Math::Complex;                       # Need complex arithmetic
$x = 2;
my $sx = eval $y;
ok($sx>0.90 and $sx<0.91);
