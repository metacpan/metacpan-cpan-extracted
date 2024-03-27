#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = parityl(2);
my $expected = "1";
is($res, $expected, "called parityl(2) and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'parityl' => '$res',");

done_testing();
