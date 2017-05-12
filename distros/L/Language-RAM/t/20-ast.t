#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 16;

my $machine = {
  error => ''
};

my ($ip, $ast) = Language::RAM::ast('INPUT 1', $machine, 1);
is($ip, -1, 'ast-io-noip');
is($machine->{'input_layout'}[0], 1, 'ast-io-input-layout');
($ip, $ast) = Language::RAM::ast('OUTPUT 2', $machine, 1);
is($ip, -1, 'ast-io-noip');
is($machine->{'output_layout'}[0], 2, 'ast-io-output-layout');

($ip, $ast) = Language::RAM::ast('a <-- 1', $machine, 1);
is($ip, 2, 'ast-simple-ip');
is($ast->[1][1], 'a', 'ast-simple-ast');
is($machine->{'lines'}{2}, 'a <-- 1', 'ast-simple-line');
$machine->{'code'}{2} = 1;

($ip, $ast) = Language::RAM::ast('3: a <-- 1', $machine, 1);
is($ip, 3, 'ast-given-ip');
is($ast->[1][1], 'a', 'ast-given-ast');
is($machine->{'lines'}{3}, 'a <-- 1', 'ast-given-line');
$machine->{'code'}{3} = 1;

($ip, $ast) = Language::RAM::ast('2: a <-- 2', $machine, 1);
is($ip, 4, 'ast-given-used-ip');
is($ast->[1][1], 'a', 'ast-given-used-ast');
is($machine->{'lines'}{4}, 'a <-- 2', 'ast-given-used-line');

($ip, $ast) = Language::RAM::ast('INPUT', $machine, 0);
is($ip, -1, 'ast-fail-ip');
is($ast, undef, 'ast-fail-ast');
is($machine->{'error'}, '1> INPUT expects an argument', 'ast-fail-error');

done_testing(16);
