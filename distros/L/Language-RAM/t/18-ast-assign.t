#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 20;

my $machine = {
  error => ''
};

my $assign = Language::RAM::ast_assign('a', '1', $machine, 0);
is($assign->[1][1], 'a', 'ast-assign-reg-imm-left');
is($assign->[2][1], '1', 'ast-assign-reg-imm-right');

$assign = Language::RAM::ast_assign('a', 's[2]', $machine, 0);
is($assign->[1][1], 'a', 'ast-assign-reg-mem-left');
is($assign->[2][1], '2', 'ast-assign-reg-mem-right');

$assign = Language::RAM::ast_assign('a', 's[i1 + 2]', $machine, 0);
is($assign->[1][1], 'a', 'ast-assign-reg-mmem-left');
is($assign->[2][1][2][1], 'i1', 'ast-assign-reg-mmem-right-reg');
is($assign->[2][1][4][1], '2', 'ast-assign-reg-mmem-right-imm');

$assign = Language::RAM::ast_assign('s[2]', 'i1', $machine, 0);
is($assign->[1][1], '2', 'ast-assign-mem-reg-left');
is($assign->[2][1], 'i1', 'ast-assign-mem-reg-right');

$assign = Language::RAM::ast_assign('s[i1 + 2]', 'a', $machine, 0);
is($assign->[2][1], 'a', 'ast-assign-mmem-reg-left');
is($assign->[1][1][2][1], 'i1', 'ast-assign-mmem-reg-right-reg');
is($assign->[1][1][4][1], '2', 'ast-assign-mmem-reg-right-imm');

$assign = Language::RAM::ast_assign('a', 'i1', $machine, 0);
is($assign->[1][1], 'a', 'ast-assign-reg-reg-left');
is($assign->[2][1], 'i1', 'ast-assign-reg-reg-right');

Language::RAM::ast_assign('a', 'jump 0', $machine, 0);
is($machine->{'error'}, '0> Expected imm, reg, mem, mmem or algo, got: jump(jump 0)', 'ast-assign-a-fail');

Language::RAM::ast_assign('i1', 's[i2 + 1]', $machine, 0);
is($machine->{'error'}, '0> Expected imm, reg, mem or algo, got: mmem(s[i2 + 1])', 'ast-assign-i1-fail');

Language::RAM::ast_assign('i1', 'a + 1', $machine, 0);
is($machine->{'error'}, '0> register a not allowed in i(1|2|3) assignment (a + 1)', 'ast-assign-index-a-fail');

Language::RAM::ast_assign('s[0]', 's[i2 + 1]', $machine, 0);
is($machine->{'error'}, '0> Expected reg, got: mmem(s[i2 + 1])', 'ast-assign-mem-fail');

Language::RAM::ast_assign('s[i1 + 1]', 's[i2 + 1]', $machine, 0);
is($machine->{'error'}, '0> Expected register a, got: mmem(s[i2 + 1])', 'ast-assign-mmem-fail');

Language::RAM::ast_assign('jump 0', 's[i2 + 1]', $machine, 0);
is($machine->{'error'}, '0> Expected reg, mem or mmem, got: jump(jump 0)', 'ast-assign-left-fail');

done_testing(20);
