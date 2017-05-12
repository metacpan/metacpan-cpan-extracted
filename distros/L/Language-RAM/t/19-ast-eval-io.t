#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 7;

my $machine = {
  error => ''
};

is(Language::RAM::ast_eval_io('1', $machine)->[0], 1, 'ast-eval-io-simple');
my $range = Language::RAM::ast_eval_io('1 3..5', $machine);
is($range->[0], 1, 'ast-eval-io-ranged1');
is($range->[1], 3, 'ast-eval-io-ranged1');
is($range->[2], 4, 'ast-eval-io-ranged1');
is($range->[3], 5, 'ast-eval-io-ranged1');

Language::RAM::ast_eval_io('1..', $machine);
is($machine->{'error'}, 'Argument not numeric: 1..', 'ast-eval-io-fail1');

Language::RAM::ast_eval_io(' ', $machine);
is($machine->{'error'}, 'Command expects argument', 'ast-eval-io-fail2');

done_testing(7);
