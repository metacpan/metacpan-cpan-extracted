#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = ctz(2);
my $expected = "1";
is($res, $expected, "called ctz(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'ctz' => '$res',");

done_testing();
