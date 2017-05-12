#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';
use Test::More;
use Config;

use_ok('Machine::Epsilon');

my $expected;

my %expected = (
    4  => 2**-23,
    8  => 2**-52,
    10 => 2**-63,
    16 => 2**-112
);

my $got = machine_epsilon();
diag("Machine epsilon is $got");
isnt($got, 1, "Didn't get 1");
cmp_ok($got + 1, '>', 1, "got greater than 0");
is(1 + $got / 2, 1, "Min epsilon");

done_testing();

