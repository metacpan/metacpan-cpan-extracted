#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = clzl(2);
my $expected = "62";
is($res, $expected, "called clzl(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'clzl' => '$res',");

done_testing();
