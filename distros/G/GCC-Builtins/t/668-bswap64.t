#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = bswap64(2);
my $expected = "144115188075855872";
is($res, $expected, "called bswap64(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'bswap64' => '$res',");

done_testing();
