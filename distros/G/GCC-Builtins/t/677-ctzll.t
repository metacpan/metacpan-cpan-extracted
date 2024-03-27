#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = ctzll(2);
my $expected = "1";
is($res, $expected, "called ctzll(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'ctzll' => '$res',");

done_testing();
