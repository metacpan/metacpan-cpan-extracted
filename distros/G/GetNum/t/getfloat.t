#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

my $class = 'GetNum';
use_ok($class) or BAIL_OUT("Can't use $class");

is(get_float(5.5),5.5,'Got correct value from float');
is(get_float('A'),undef,'Got undef from string');
is(get_float(undef),undef,'Got undef from undef');
is(get_float(0),0,'Got 0 from 0');
is(get_float('0'),0,'Got 0 from 0 string');
is(get_float('5.5'),5.5,'Got correct value from float string');
is(get_int({}),undef,'Got undef from anon hash');

done_testing();
