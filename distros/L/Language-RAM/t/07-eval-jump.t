#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 1;

my $machine = {
  stats => {
    memory_usage => {}
  },
  memory => {},
  ip => 0
};

Language::RAM::eval_jump([('jump', [('imm', 2)])], $machine);
is($machine->{'ip'}, 1, 'eval-jump');

done_testing(1);
