#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 7;

my $machine = {
  stats => {
    memory_usage => {}
  }
};

is(Language::RAM::inc_mem_stat($machine, 2, 1), 1, 'inc-mem-stat-write');
is(Language::RAM::inc_mem_stat($machine, 2, 0), 1, 'inc-mem-stat-read');

is(Language::RAM::inc_mem_stat($machine, 2, 1), 2, 'inc-mem-stat-write-2');
is(Language::RAM::inc_mem_stat($machine, 2, 0), 2, 'inc-mem-stat-read-2');
is(Language::RAM::inc_mem_stat($machine, 2, 0), 3, 'inc-mem-stat-read-3');

is($machine->{'stats'}{'memory_usage'}{2}[0], 3, 'inc-mem-stat-read-end');
is($machine->{'stats'}{'memory_usage'}{2}[1], 2, 'inc-mem-stat-write-end');

done_testing(7);
