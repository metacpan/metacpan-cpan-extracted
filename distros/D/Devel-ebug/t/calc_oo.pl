#!perl
use strict;
use warnings;
use lib "t";
use Calc;

my $calc = Calc->new;
my $r = $calc->add(5, 10); # 15
my $f = $calc->fib1($r); # 987
my $f2 = $calc->fib2($r); # 987
my $f3 = 1; # breakable line
