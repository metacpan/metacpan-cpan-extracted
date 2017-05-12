#!perl

my $q = 1;
my $w = 2;

use lib "t";
eval "use Calc";


print "after Calc.pm is loaded";

eval "Calc::add(1,2)";
