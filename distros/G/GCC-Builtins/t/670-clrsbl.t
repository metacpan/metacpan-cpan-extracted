#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = clrsbl(2);
my $expected = "61";
is($res, $expected, "called clrsbl(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'clrsbl' => '$res',");

done_testing();
