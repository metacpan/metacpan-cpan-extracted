#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

use GCC::Builtins qw/:all/;

my $res = infd128();
my $expected = "Inf";
is($res, $expected, "called infd128() and got result ($res), expected ($expected).");
diag("copy-this-expected-value 'infd128' => '$res',");

done_testing();
