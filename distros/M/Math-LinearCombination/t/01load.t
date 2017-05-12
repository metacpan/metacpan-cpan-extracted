#!perl
use strict;
use Test;
BEGIN { plan tests => 1 }

eval "use Math::LinearCombination";
ok(length($@) == 0); # 1

 
