#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 24;

my $machine = {
  stats => {
    memory_usage => {}
  },
  memory => {a => 0, i1 => -1, i2 => 2}
};

is(Language::RAM::eval_cond([('cond', [('reg', 'a')], '<')], $machine), !1, 'eval-cond-reg-a-<');
is(Language::RAM::eval_cond([('cond', [('reg', 'a')], '<=')], $machine), !0, 'eval-cond-reg-a-<=');
is(Language::RAM::eval_cond([('cond', [('reg', 'a')], '=')], $machine), !0, 'eval-cond-reg-a-=');
is(Language::RAM::eval_cond([('cond', [('reg', 'a')], '!=')], $machine), !1, 'eval-cond-reg-a-!=');
is(Language::RAM::eval_cond([('cond', [('reg', 'a')], '>=')], $machine), !0, 'eval-cond-reg-a->=');
is(Language::RAM::eval_cond([('cond', [('reg', 'a')], '>')], $machine), !1, 'eval-cond-reg-a->');

is(Language::RAM::eval_cond([('cond', [('reg', 'i1')], '<')], $machine), !0, 'eval-cond-reg-i1-<');
is(Language::RAM::eval_cond([('cond', [('reg', 'i1')], '<=')], $machine), !0, 'eval-cond-reg-i1-<=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i1')], '=')], $machine), !1, 'eval-cond-reg-i1-=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i1')], '!=')], $machine), !0, 'eval-cond-reg-i1-!=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i1')], '>=')], $machine), !1, 'eval-cond-reg-i1->=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i1')], '>')], $machine), !1, 'eval-cond-reg-i1->');

is(Language::RAM::eval_cond([('cond', [('reg', 'i2')], '<')], $machine), !1, 'eval-cond-reg-i2-<');
is(Language::RAM::eval_cond([('cond', [('reg', 'i2')], '<=')], $machine), !1, 'eval-cond-reg-i2-<=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i2')], '=')], $machine), !1, 'eval-cond-reg-i2-=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i2')], '!=')], $machine), !0, 'eval-cond-reg-i2-!=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i2')], '>=')], $machine), !0, 'eval-cond-reg-i2->=');
is(Language::RAM::eval_cond([('cond', [('reg', 'i2')], '>')], $machine), !0, 'eval-cond-reg-i2->');

is($machine->{'stats'}{'memory_usage'}{'a'}[0], 6, 'eval-cond-reg-a-read-stats');
is($machine->{'stats'}{'memory_usage'}{'a'}[1], 0, 'eval-cond-reg-a-write-stats');

is($machine->{'stats'}{'memory_usage'}{'i1'}[0], 6, 'eval-cond-reg-i1-read-stats');
is($machine->{'stats'}{'memory_usage'}{'i1'}[1], 0, 'eval-cond-reg-i1-write-stats');

is($machine->{'stats'}{'memory_usage'}{'i2'}[0], 6, 'eval-cond-reg-i2-read-stats');
is($machine->{'stats'}{'memory_usage'}{'i2'}[1], 0, 'eval-cond-reg-i2-write-stats');

done_testing(24);
