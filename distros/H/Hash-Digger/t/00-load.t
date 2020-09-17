#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

eval 'use Hash::Digger';
ok ! $@, 'Can use Module';
