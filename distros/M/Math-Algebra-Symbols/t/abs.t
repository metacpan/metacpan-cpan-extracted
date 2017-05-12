#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: dot operator.  Note the low priority
# of the ^ operator.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use strict;
use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($x, $i) = symbols(qw(x i));

ok(  abs($x+$i*$x)  ==  sqrt(2*$x**2)  );
ok(  abs($x+$i*$x)  !=  sqrt(2*$x**3)  );
ok(  abs($x+$i*$x) <=> 'sqrt(2*$x**2)' );

