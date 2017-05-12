use strict;
use warnings;
use Test::More;
use t::Testee qw(TYPE_C TYPE_D);

is(TYPE_C, 1919);
is(TYPE_D, 0721);

done_testing;

