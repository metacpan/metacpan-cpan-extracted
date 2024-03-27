#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = powi(2.56,2);
my $expected = "6.5536";
is($res, $expected, "called powi(2.56,2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'powi' => '$res',");

done_testing();
