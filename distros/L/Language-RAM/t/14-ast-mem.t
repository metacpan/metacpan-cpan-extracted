#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 5;

my $machine = {
  error => ''
};

is(Language::RAM::ast_mem('1', $machine, 1)->[1], 1, 'mem');
is(Language::RAM::ast_mem('i1', $machine, 1)->[1][1], 'i1', 'reg');
is(Language::RAM::ast_mem('i1 + 1', $machine, 1)->[1][2][1], 'i1', 'algo');

Language::RAM::ast_mem('s[0]', $machine, 1);
is($machine->{'error'}, '1> Expected imm, algo or index register, got: mem(s[0])', 'mem');

Language::RAM::ast_mem('a + 1', $machine, 1);
is($machine->{'error'}, '1> Cannot use register a in mmem (a + 1)', 'mem');

done_testing(5);
