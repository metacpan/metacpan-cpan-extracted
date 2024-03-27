#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = nanl('some string');
my $expected = "NaN";
is($res, $expected, "called nanl('some string') and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'nanl' => '$res',");

done_testing();
