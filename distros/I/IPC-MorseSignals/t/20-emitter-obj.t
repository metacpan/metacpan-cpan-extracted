#!perl -T

use strict;
use warnings;

use Test::More tests => 19;

use IPC::MorseSignals::Emitter;

sub neq { abs($_[0] - $_[1]) < ($_[1] / 10) };

my $deuce = IPC::MorseSignals::Emitter->new;
ok(defined $deuce, 'BME object is defined');
is(ref $deuce, 'IPC::MorseSignals::Emitter', 'IME object is valid');
ok($deuce->isa('Bit::MorseSignals::Emitter'), 'IME is a BME');

my $fake = { };
bless $fake, 'IPC::MorseSignal::Hlagh';
eval { IPC::MorseSignals::Emitter::speed($fake) };
ok($@ && $@ =~ /^First\s+argument/, "IME methods only apply to IME objects");
eval { Bit::MorseSignals::Emitter::reset($fake) };
ok($@ && $@ =~ /^First\s+argument/, "BME methods only apply to BME objects");

is($deuce->delay, 1, 'default delay is 1');
is($deuce->speed, 1, 'default speed is 1');

$deuce->delay(0.1);
ok(neq($deuce->delay, 0.1), 'set delay is 0.1');
is($deuce->speed, 10, 'resulting speed is 10');

$deuce->speed(100);
is($deuce->speed, 100, 'set speed is 100');
ok(neq($deuce->delay, 0.01), 'resulting speed is 0.01');

$deuce = IPC::MorseSignals::Emitter->new(delay => 0.25);
ok(neq($deuce->delay, 0.25), 'initial delay is 0.25');
is($deuce->speed, 4, 'resulting initial speed is 4');

$deuce = IPC::MorseSignals::Emitter->new(speed => 40);
is($deuce->speed, 40, 'initial speed is 40');
ok(neq($deuce->delay, 0.025), 'resulting initial delay is 0.025');

$deuce = IPC::MorseSignals::Emitter->new(delay => 0.25, speed => 40);
ok(neq($deuce->delay, 0.25), 'delay supersedes speed');

$deuce = IPC::MorseSignals::Emitter->new(delay => 0);
is($deuce->delay, 1, 'wrong delay results in 1');

$deuce = IPC::MorseSignals::Emitter->new(speed => 0.1);
is($deuce->delay, 1, 'wrong speed results in 1');

$deuce = IPC::MorseSignals::Emitter->new(delay => 0, speed => -0.1);
is($deuce->delay, 1, 'wrong delay and speed result in 1');
