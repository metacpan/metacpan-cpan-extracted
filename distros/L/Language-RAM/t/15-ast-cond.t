#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 25;

my $machine = {
  error => ''
};

is(Language::RAM::ast_cond('a', '<', $machine, 1)->[1][1], 'a', 'reg-a-<');
is(Language::RAM::ast_cond('a', '<', $machine, 1)->[2], '<', 'op-a-<');

is(Language::RAM::ast_cond('a', '<=', $machine, 1)->[1][1], 'a', 'reg-a-<=');
is(Language::RAM::ast_cond('a', '<=', $machine, 1)->[2], '<=', 'op-a-<=');

is(Language::RAM::ast_cond('a', '=', $machine, 1)->[1][1], 'a', 'reg-a-=');
is(Language::RAM::ast_cond('a', '=', $machine, 1)->[2], '=', 'op-a-=');

is(Language::RAM::ast_cond('a', '!=', $machine, 1)->[1][1], 'a', 'reg-a-!=');
is(Language::RAM::ast_cond('a', '!=', $machine, 1)->[2], '!=', 'op-a-!=');

is(Language::RAM::ast_cond('a', '>=', $machine, 1)->[1][1], 'a', 'reg-a->=');
is(Language::RAM::ast_cond('a', '>=', $machine, 1)->[2], '>=', 'op-a->=');

is(Language::RAM::ast_cond('a', '>', $machine, 1)->[1][1], 'a', 'reg-a->');
is(Language::RAM::ast_cond('a', '>', $machine, 1)->[2], '>', 'op-a->');

is(Language::RAM::ast_cond('i1', '<', $machine, 1)->[1][1], 'i1', 'reg-i1-<');
is(Language::RAM::ast_cond('i1', '<', $machine, 1)->[2], '<', 'op-i1-<');

is(Language::RAM::ast_cond('i1', '<=', $machine, 1)->[1][1], 'i1', 'reg-i1-<=');
is(Language::RAM::ast_cond('i1', '<=', $machine, 1)->[2], '<=', 'op-i1-<=');

is(Language::RAM::ast_cond('i1', '=', $machine, 1)->[1][1], 'i1', 'reg-i1-=');
is(Language::RAM::ast_cond('i1', '=', $machine, 1)->[2], '=', 'op-i1-=');

is(Language::RAM::ast_cond('i1', '!=', $machine, 1)->[1][1], 'i1', 'reg-i1-!=');
is(Language::RAM::ast_cond('i1', '!=', $machine, 1)->[2], '!=', 'op-i1-!=');

is(Language::RAM::ast_cond('i1', '>=', $machine, 1)->[1][1], 'i1', 'reg-i1->=');
is(Language::RAM::ast_cond('i1', '>=', $machine, 1)->[2], '>=', 'op-i1->=');

is(Language::RAM::ast_cond('i1', '>', $machine, 1)->[1][1], 'i1', 'reg-i1->');
is(Language::RAM::ast_cond('i1', '>', $machine, 1)->[2], '>', 'op-i1->');

Language::RAM::ast_cond('1', '<=', $machine, 1);
is($machine->{'error'}, '1> Expected reg, got: imm(1)', 'imm');

done_testing(25);
