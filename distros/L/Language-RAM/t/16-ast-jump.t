#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 2;

my $machine = {
  error => ''
};

is(Language::RAM::ast_jump('2', $machine, 0)->[1][1], '2', 'ast-jump');

Language::RAM::ast_jump('a', $machine, 0);
is($machine->{'error'}, '0> Expected imm, got: reg(a)', 'ast-jump-fail');

done_testing(2);
