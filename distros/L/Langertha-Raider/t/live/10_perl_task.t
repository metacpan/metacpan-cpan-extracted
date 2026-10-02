#!/usr/bin/env perl
# ABSTRACT: Live task -- raider --perl builds a small module + test in a fresh workspace

use strict;
use warnings;
use lib 't/lib';
use Test::Raider::Live qw( live_opt_in run_raider_task check_journal );
BEGIN { live_opt_in() }
use Test2::V0;
use Path::Tiny;

# Opt-in (RAIDER_LIVE_TASKS=1), costs real money. Drives bin/raider as a
# subprocess like a user. A provider error is a FAILURE here, never a skip.
# See Test::Raider::Live for the provider knobs.

my $run = run_raider_task(
  flags  => ['--perl'],
  seed   => sub { $_[0]->child('cpanfile')->spew_utf8("on test => sub {\n  requires 'Test::More';\n};\n") },
  prompt => <<'P',
Create lib/RaiderProbe/Counter.pm (package RaiderProbe::Counter) with a class
method add($class, $a, $b) that returns the sum of $a and $b, and t/counter.t
testing it with Test::More. Then run `prove -l t` and make sure it passes.
Be brief: use as few tool calls as you can.
P
);

ok(!$run->{timed_out}, 'raider finished within the timeout') or diag $run->{output};
is($run->{exit}, 0, 'bin/raider exits 0') or diag $run->{output};

my $ws = $run->{workspace};
ok($ws->child('lib', 'RaiderProbe', 'Counter.pm')->is_file, 'module written');
ok($ws->child('t', 'counter.t')->is_file, 'test written');

# Independent checks, not the agent's word for it.
my $prove = `cd '$ws' && $^X -S prove -l t 2>&1`;
is($? >> 8, 0, 'prove -l t is green in the workspace') or diag $prove;

my $sum = `cd '$ws' && $^X -Ilib -MRaiderProbe::Counter -e 'print RaiderProbe::Counter->add(40, 2)' 2>&1`;
is($sum, '42', 'RaiderProbe::Counter->add(40, 2) is 42');

check_journal($run);

done_testing;
