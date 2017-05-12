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
  memory => {}
};

is(Language::RAM::eval_mmem([('mmem', [('algo', 1, [qw(reg a)], '+', [qw(imm 2)])])], $machine), 0, 'eval-mmem-init');
is(Language::RAM::eval_mmem([('mmem', [('algo', 1, [qw(reg a)], '+', [qw(imm 2)])])], $machine, 1), \$machine->{'memory'}{2}, 'eval-mmem-ref');
is(Language::RAM::eval_mmem([('mmem', [('algo', 1, [qw(reg a)], '+', [qw(imm 2)])])], $machine, 2), 2, 'eval-mmem-addr');
Language::RAM::eval_mmem([('mmem', [('algo', 1, [qw(reg a)], '+', [qw(imm 2)])])], $machine, 1);
is($machine->{'stats'}{'memory_usage'}{2}[0], 1, 'eval-mmem-read-stats');
is($machine->{'stats'}{'memory_usage'}{2}[1], 2, 'eval-mmem-write-stats');
is($machine->{'error'}, undef, 'eval-mmem-no-error');

done_testing(6);
