#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = huge_val();
my $expected = "Inf";
is($res, $expected, "called huge_val() and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'huge_val' => '$res',");

done_testing();
