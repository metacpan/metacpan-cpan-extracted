#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 1;

is(Language::RAM::ast_imm('2')->[1], 2, 'ast-imm');

done_testing(1);
