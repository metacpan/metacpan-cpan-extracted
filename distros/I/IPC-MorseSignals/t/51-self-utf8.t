#!perl -T

use strict;
use warnings;

use utf8;

use Test::More tests => 7;

use IPC::MorseSignals::Emitter;
use IPC::MorseSignals::Receiver;

my @msgs = qw/€éèë 月語 x tata たTÂ/;

sub cp { join '.', map ord, split //, $_[0] }

my $deuce = IPC::MorseSignals::Emitter->new(speed => 1024);
my $pants = IPC::MorseSignals::Receiver->new(\%SIG, done => sub {
 my $cur = shift @msgs;
 ok($_[1] eq $cur, 'got ' . cp($_[1]) . ', expected ' . cp($cur))
});

$deuce->post($_) for @msgs;
$deuce->send($$);

ok(!$deuce->busy, 'emitter is no longer busy after all the messages have been sent');
ok(!$pants->busy, 'receiver is no longer busy after all the messages have been got');

ok(0, 'didn\'t got ' . cp($_)) for @msgs;
