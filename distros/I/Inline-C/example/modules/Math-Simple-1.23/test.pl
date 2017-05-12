use strict;
use Test::More tests => 2;
use Math::Simple qw(add subtract);
is add(5, 7), 12;
is subtract(5, 7), -2;
