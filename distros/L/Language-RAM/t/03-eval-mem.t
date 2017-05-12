#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 5;

my $machine = {
  stats => {
    memory_usage => {}
  },
  memory => {}
};

is(Language::RAM::eval_mem([('mem', 2)], $machine), 0, 'eval-mem-init');
is(Language::RAM::eval_mem([('mem', 2)], $machine, 1), \$machine->{'memory'}{2}, 'eval-mem-ref');
is(Language::RAM::eval_mem([('mem', 2)], $machine, 2), 2, 'eval-mem-addr');
Language::RAM::eval_mem([('mem', 2)], $machine, 1);
is($machine->{'stats'}{'memory_usage'}{2}[0], 1, 'eval-mem-read-stats');
is($machine->{'stats'}{'memory_usage'}{2}[1], 2, 'eval-mem-write-stats');

done_testing(5);
