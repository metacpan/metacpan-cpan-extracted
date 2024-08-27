#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.06'; 

use GCC::Builtins;

my $res = GCC::Builtins::clz(10);
is($res, 28, "clz(10) : result is $res, expected 28");

done_testing();
