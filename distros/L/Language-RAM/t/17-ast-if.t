#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 4;

my $machine = {
  error => ''
};

my $cond = Language::RAM::ast_cond_jump('a <= 0', 'jump 2', $machine, 0);
is($cond->[1][1][1], 'a', 'ast-cond-jump-reg');
is($cond->[1][2], '<=', 'ast-cond-jump-op');

Language::RAM::ast_cond_jump('a', 'jump 2', $machine, 0);
is($machine->{'error'}, '0> Expected cond, got: reg(a)', 'ast-cond-jump-fail-cond');

Language::RAM::ast_cond_jump('a <= 0', 'a', $machine, 0);
is($machine->{'error'}, '0> Expected jump, got: reg(a)', 'ast-cond-jump-fail-jump');

done_testing(4);
