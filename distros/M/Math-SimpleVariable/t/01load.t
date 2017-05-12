#!perl
use strict;
use Test;
BEGIN { plan tests => 1 }

# test the loading of the module
eval "use Math::SimpleVariable";
ok(length($@) == 0);
