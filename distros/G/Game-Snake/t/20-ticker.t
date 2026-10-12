#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Snake::Ticker;

# LOST TIME IS DROPPED, NEVER CAUGHT UP. A tick that is overdue fires once and
# the schedule restarts from now. Measured here with a clock the test moves.

my $now = 10;
my $ticker = Game::Snake::Ticker->new(clock => sub { $now });

is($ticker->remaining, 0, 'nothing is due before start');
$ticker->start(0.5);
is($ticker->remaining, 0.5, 'half a second to the first tick');
ok(!$ticker->due, 'not due');

$now = 10.2;
cmp_ok(abs($ticker->remaining - 0.3), '<', 1e-9, 'a fifth of a second later, 0.3 remain');

$now = 10.6;
is($ticker->remaining, 0, 'past the deadline, nothing remains');
ok($ticker->due, 'and it is due');

$ticker->tick(0.5);
is($ticker->ticks, 1, 'one tick counted');
is($ticker->late, 0, 'not late');
cmp_ok(abs($ticker->next - 11.0), '<', 1e-9, 'the next tick is one period on from the last, not from now');

$now = 13.7;
$ticker->tick(0.5);
is($ticker->ticks, 2, 'two ticks');
is($ticker->late, 1, 'this one was late');
cmp_ok(abs($ticker->next - 14.2), '<', 1e-9, 'and the schedule restarted from now, not from 11.5');

$now = 14.0;
cmp_ok(abs($ticker->remaining - 0.2), '<', 1e-9, 'remaining counts from the restarted schedule');
$now = 15.0;
is($ticker->remaining, 0, 'and is never negative');

$ticker->start(1);
cmp_ok(abs($ticker->next - 16.0), '<', 1e-9, 'start resets the schedule');
is($ticker->ticks, 2, 'without touching the count');

my $bad = eval { Game::Snake::Ticker->new(clock => 'now') };
like($@, qr/the clock is a code reference/, 'a clock that is not code dies');

my $real = Game::Snake::Ticker->new;
is(ref $real->clock, 'CODE', 'the default clock is code');
cmp_ok($real->clock->(), '>', 1_000_000_000, 'and reads the wall');

done_testing();
