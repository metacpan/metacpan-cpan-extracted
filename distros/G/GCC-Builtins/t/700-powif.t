#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = powif(2.56,2);
my $expected = "6.55359983444214";
is($res, $expected, "called powif(2.56,2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'powif' => '$res',");

done_testing();
