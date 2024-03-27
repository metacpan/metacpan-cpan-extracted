#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = nan('some string');
my $expected = "NaN";
is($res, $expected, "called nan('some string') and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'nan' => '$res',");

done_testing();
