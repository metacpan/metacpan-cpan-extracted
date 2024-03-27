#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = popcountll(2);
my $expected = "1";
is($res, $expected, "called popcountll(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'popcountll' => '$res',");

done_testing();
