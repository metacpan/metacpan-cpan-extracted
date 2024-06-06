#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Extism::XS;

plan tests => 1;

ok(Extism::XS::version());