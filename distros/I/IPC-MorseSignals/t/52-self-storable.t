#!perl -T

use strict;
use warnings;

use utf8;

use Test::More tests => 10;

use IPC::MorseSignals::Emitter;
use IPC::MorseSignals::Receiver;

my @msgs = (
 \(undef, -273, 1.4159, 'yes', '¥€$'),
 [ 5, 6, 7 ],
 { hlagh => 1, HLAGH => 2 },
 { lol => [ 'bleh', undef, 4684324 ] },
);
$msgs[7]->{wut} = { dong => [ 0 .. 9 ], recurse => $msgs[7] };
my $i = 0;

my $deuce = IPC::MorseSignals::Emitter->new(speed => 1024);
my $pants = IPC::MorseSignals::Receiver->new(\%SIG, done => sub {
 my $cur = shift @msgs;
 is_deeply($_[1], $cur, 'got object ' . $i++);
});

$deuce->post($_) for @msgs;
$deuce->send($$);

ok(!$deuce->busy, 'emitter is no longer busy after all the messages have been sent');
ok(!$pants->busy, 'receiver is no longer busy after all the messages have been got');

ok(0, 'didn\'t got object ' . $i++) for @msgs;
