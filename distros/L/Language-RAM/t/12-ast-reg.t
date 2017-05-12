#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 1;

is(Language::RAM::ast_reg('a')->[1], 'a', 'ast-reg');

done_testing(1);
