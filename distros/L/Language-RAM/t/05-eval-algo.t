#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 25;

my $machine = {
  stats => {
    memory_usage => {}
  },
  memory => {i1 => 10, a => 5, 2 => 1, 7 => 1}
};

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '+', [('imm', 2)])], $machine), 7, 'eval-algo-reg-a-imm-plus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '+', [('mem', 2)])], $machine), 6, 'eval-algo-reg-a-mem-plus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '+', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 6, 'eval-algo-reg-a-mmem-plus');

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '-', [('imm', 2)])], $machine), 3, 'eval-algo-reg-a-imm-minus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '-', [('mem', 2)])], $machine), 4, 'eval-algo-reg-a-mem-minus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '-', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 4, 'eval-algo-reg-a-mmem-minus');

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '*', [('imm', 2)])], $machine), 10, 'eval-algo-reg-a-imm-mult');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '*', [('mem', 2)])], $machine), 5, 'eval-algo-reg-a-mem-mult');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], '*', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 5, 'eval-algo-reg-a-mmem-mult');

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], 'div', [('imm', 2)])], $machine), 2, 'eval-algo-reg-a-imm-div');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], 'div', [('mem', 2)])], $machine), 5, 'eval-algo-reg-a-mem-div');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], 'div', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 5, 'eval-algo-reg-a-mmem-div');

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], 'mod', [('imm', 2)])], $machine), 1, 'eval-algo-reg-a-imm-mod');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], 'mod', [('mem', 2)])], $machine), 0, 'eval-algo-reg-a-mem-mod');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'a')], 'mod', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 0, 'eval-algo-reg-a-mmem-mod');

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'i1')], '+', [('imm', 2)])], $machine), 12, 'eval-algo-reg-i1-imm-plus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'i1')], '+', [('mem', 2)])], $machine), 11, 'eval-algo-reg-i1-mem-plus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'i1')], '+', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 11, 'eval-algo-reg-i1-mmem-plus');

is(Language::RAM::eval_algo([('algo', 1, [('reg', 'i1')], '-', [('imm', 2)])], $machine), 8, 'eval-algo-reg-i1-imm-minus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'i1')], '-', [('mem', 2)])], $machine), 9, 'eval-algo-reg-i1-mem-minus');
is(Language::RAM::eval_algo([('algo', 1, [('reg', 'i1')], '-', [('mmem', [('algo', 1, [('reg', 'a')], '+', [('imm', 2)])])])], $machine), 9, 'eval-algo-reg-i1-mmem-minus');

is($machine->{'stats'}{'memory_usage'}{'a'}[0], 22, 'eval-algo-reg-a-read-stats');
is($machine->{'stats'}{'memory_usage'}{'a'}[1], 0, 'eval-algo-reg-a-write-stats');

is($machine->{'stats'}{'memory_usage'}{'i1'}[0], 6, 'eval-algo-reg-i1-read-stats');
is($machine->{'stats'}{'memory_usage'}{'i1'}[1], 0, 'eval-algo-reg-i1-write-stats');

done_testing(25);
