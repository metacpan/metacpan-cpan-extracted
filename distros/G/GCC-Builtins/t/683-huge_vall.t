#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = huge_vall();
my $expected = "Inf";
is($res, $expected, "called huge_vall() and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'huge_vall' => '$res',");

done_testing();
