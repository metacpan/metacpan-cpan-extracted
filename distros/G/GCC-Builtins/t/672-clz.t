#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = clz(2);
my $expected = "30";
is($res, $expected, "called clz(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'clz' => '$res',");

done_testing();
