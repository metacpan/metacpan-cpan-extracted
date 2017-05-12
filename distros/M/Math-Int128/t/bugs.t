#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

use Math::Int128 qw( string_to_uint128 );
use Math::Int128::die_on_overflow;

#101982
my $hex = "0xffffffffffffffffffffffffffffffff";
my $dec = "340282366920938463463374607431768211455";
my $v1 = string_to_uint128($hex);
my $v2 = string_to_uint128($dec);
is("$v1", "$v2", "#101982: strtoint128");

done_testing();
