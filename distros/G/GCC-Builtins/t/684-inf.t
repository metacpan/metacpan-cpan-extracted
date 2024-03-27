#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = inf();
my $expected = "Inf";
is($res, $expected, "called inf() and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'inf' => '$res',");

done_testing();
