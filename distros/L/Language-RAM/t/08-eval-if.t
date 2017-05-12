#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 2;

my $machine = {
  stats => {
    memory_usage => {}
  },
  memory => {a => 1},
  ip => 0
};

Language::RAM::eval_if([('if', [('cond', [('reg', 'a')], '>')], [('jump', [('imm', 2)])])], $machine);
is($machine->{'ip'}, 1, 'eval-jump');
Language::RAM::eval_if([('if', [('cond', [('reg', 'a')], '<')], [('jump', [('imm', 3)])])], $machine);
is($machine->{'ip'}, 1, 'eval-jump');

done_testing(2);
