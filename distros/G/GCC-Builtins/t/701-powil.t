#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = powil(2,2);
my $expected = "4";
is($res, $expected, "called powil(2,2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'powil' => '$res',");

done_testing();
