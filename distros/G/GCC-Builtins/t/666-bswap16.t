#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = bswap16(2);
my $expected = "512";
is($res, $expected, "called bswap16(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'bswap16' => '$res',");

done_testing();
