#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = ffsll(2);
my $expected = "2";
is($res, $expected, "called ffsll(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'ffsll' => '$res',");

done_testing();
