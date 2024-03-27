#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = bswap32(2);
my $expected = "33554432";
is($res, $expected, "called bswap32(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'bswap32' => '$res',");

done_testing();
