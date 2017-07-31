#!perl -T

use strict;
use warnings;

use Test::More tests => 10 + 7;

require IPC::MorseSignals::Emitter;

for (qw<new post pop reset flush busy queued>, qw<new send delay speed>) {
 ok(IPC::MorseSignals::Emitter->can($_), 'IME can ' . $_);
}

require IPC::MorseSignals::Receiver;

for (qw<new push reset busy msg>, qw<new>) {
 ok(IPC::MorseSignals::Receiver->can($_), 'IMR can ' . $_);
}

