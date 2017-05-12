#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

use IPC::MorseSignals::Emitter;
use IPC::MorseSignals::Receiver;

my @msgs = qw/hlagh hlaghlaghlagh HLAGH HLAGHLAGHLAGH \x{0dd0}\x{00}
              h\x{00}la\x{00}gh \x{00}\x{ff}\x{ff}\x{00}\x{00}\x{ff}/;

my $deuce = IPC::MorseSignals::Emitter->new(speed => 1024);
my $pants = IPC::MorseSignals::Receiver->new(\%SIG, done => sub {
 my $cur = shift @msgs;
 is($_[1], $cur, "message correctly received");
});

$deuce->post($_) for @msgs;
$deuce->send($$);

ok(!$deuce->busy, 'emitter is no longer busy after all the messages have been sent');
ok(!$pants->busy, 'receiver is no longer busy after all the messages have been got');

ok(0, "didn't got $_") for @msgs;
