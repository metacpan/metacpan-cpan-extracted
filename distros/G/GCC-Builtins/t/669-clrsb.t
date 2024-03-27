#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = clrsb(2);
my $expected = "29";
is($res, $expected, "called clrsb(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'clrsb' => '$res',");

done_testing();
