#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = inff();
my $expected = "Inf";
is($res, $expected, "called inff() and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'inff' => '$res',");

done_testing();
