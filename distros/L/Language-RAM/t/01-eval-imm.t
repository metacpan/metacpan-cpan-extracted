#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 1;

is(Language::RAM::eval_imm([qw(imm 2)]), 2, 'eval-imm');

done_testing(1);
