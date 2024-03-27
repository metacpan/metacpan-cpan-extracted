#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = ffsl(2);
my $expected = "2";
is($res, $expected, "called ffsl(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'ffsl' => '$res',");

done_testing();
