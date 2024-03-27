#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = infd64();
my $expected = "Inf";
is($res, $expected, "called infd64() and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'infd64' => '$res',");

done_testing();
