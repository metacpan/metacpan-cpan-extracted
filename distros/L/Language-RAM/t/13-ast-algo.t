#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 23;

my $machine = {
  error => '',
  memory => {0 => 1, i1 => 2}
};

my $algo = Language::RAM::ast_algo('a', '+', '2', $machine, 0);
is($algo->[1], !0, 'algo-a-imm-type');
is($algo->[2][1], 'a', 'algo-a-imm-left');
is($algo->[3], '+', 'algo-a-imm-op');
is($algo->[4][1], '2', 'algo-a-imm-right');

$algo = Language::RAM::ast_algo('a', '-', 's[0]', $machine, 0);
is($algo->[1], !0, 'algo-a-mem-type');
is($algo->[2][1], 'a', 'algo-a-mem-left');
is($algo->[3], '-', 'algo-a-mem-op');
is($algo->[4][1], '0', 'algo-a-mem-right');

$algo = Language::RAM::ast_algo('a', '*', 's[i1 + 2]', $machine, 0);
is($algo->[1], !0, 'algo-a-mmem-type');
is($algo->[2][1], 'a', 'algo-a-mmem-left');
is($algo->[3], '*', 'algo-a-mmem-op');
is($algo->[4][0], 'mmem', 'algo-a-mmem-right-type');
is($algo->[4][1][1], !1, 'algo-a-mmem-right-inner-type');
is($algo->[4][1][2][1], 'i1', 'algo-a-mmem-right-inner-left');
is($algo->[4][1][3], '+', 'algo-a-mmem-right-inner-op');
is($algo->[4][1][4][1], '2', 'algo-a-mmem-right-inner-right');

$algo = Language::RAM::ast_algo('i1', '+', '2', $machine, 0);
is($algo->[1], !1, 'algo-reg-imm-type');
is($algo->[2][1], 'i1', 'algo-reg-imm-left');
is($algo->[3], '+', 'algo-reg-imm-op');
is($algo->[4][1], '2', 'algo-reg-imm-right');

$algo = Language::RAM::ast_algo('a', '+', 'i1', $machine, 0);
is($machine->{'error'}, '0> Expected imm, mem or mmem, got: reg(i1)', 'algo-fail-reg-reg');

$algo = Language::RAM::ast_algo('1', '+', 'i1', $machine, 0);
is($machine->{'error'}, '0> Expected reg, got: imm(1)', 'algo-fail-imm-reg');

$algo = Language::RAM::ast_algo('i1', '*', '1', $machine, 0);
is($machine->{'error'}, '0> Index register only allows addition or subtraction with imm (i1*1)', 'algo-fail-index-wrong-math');

done_testing(23);
