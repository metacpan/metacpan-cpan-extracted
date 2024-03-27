#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = nanf('some string');
my $expected = "NaN";
is($res, $expected, "called nanf('some string') and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'nanf' => '$res',");

done_testing();
