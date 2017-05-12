#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 6;

my $machine = {
  stats => {
    memory_usage => {}
  },
  memory => {a => 1, 0 => 2, 2 => 3, i2 => 4},
  ip => 0
};

Language::RAM::eval_assign([('assign', [('reg', 'i1')], [('imm', 2)])], $machine);
is($machine->{'memory'}{'i1'}, 2, 'eval-assign-reg-imm');

Language::RAM::eval_assign([('assign', [('reg', 'i1')], [('mem', 2)])], $machine);
is($machine->{'memory'}{'i1'}, 3, 'eval-assign-reg-mem');

Language::RAM::eval_assign([('assign', [('reg', 'a')], [('mmem', [('reg', 'i1')])])], $machine);
is($machine->{'memory'}{'a'}, 0, 'eval-assign-a-mmem');

Language::RAM::eval_assign([('assign', [('mem', 1)], [('reg', 'i1')])], $machine);
is($machine->{'memory'}{1}, 3, 'eval-assign-mem-reg');

Language::RAM::eval_assign([('assign', [('mmem', [('reg', 'i1')])], [('reg', 'a')])], $machine);
is($machine->{'memory'}{'3'}, 0, 'eval-assign-mmem-a');

Language::RAM::eval_assign([('assign', [('reg', 'i1')], [('reg', 'a')])], $machine);
is($machine->{'memory'}{'i1'}, 0, 'eval-assign-reg-reg');

done_testing(6);
