#!perl -w

use strict;
$^W=1;

use Test;
BEGIN { plan tests => 6, todo => [] }

BEGIN { $ENV{MATH_ROUND_FAIR_DEBUG} = 1 }
use Math::Round::Fair qw(round_adjacent);

srand(0);
my @result = round_adjacent();
ok(@result==0);
@result = round_adjacent(1.23, 4.56, 7.89);
ok(@result==3);
ok($result[0]==1 || $result[0]==2);
ok($result[1]==4 || $result[1]==5);
ok($result[2]==7 || $result[2]==8);
my $sum=0.0;
$sum += $_ for(@result);
ok($sum==13 || $sum==14);
