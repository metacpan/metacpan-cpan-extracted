#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = clrsbll(2);
my $expected = "61";
is($res, $expected, "called clrsbll(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'clrsbll' => '$res',");

done_testing();
