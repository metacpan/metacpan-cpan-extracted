#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use IPC::MorseSignals::Receiver;

my $pants = IPC::MorseSignals::Receiver->new(\%SIG);
ok(defined $pants, 'IMR object is defined');
is(ref $pants, 'IPC::MorseSignals::Receiver', 'IMR object is valid');
ok($pants->isa('Bit::MorseSignals::Receiver'), 'IMR is a BMR');

my $fake = { };
bless $fake, 'IPC::MorseSignal::Hlagh';
eval { Bit::MorseSignals::Receiver::reset($fake) };
ok($@ && $@ =~ /^First\s+argument/, "BMR methods only apply to BMR objects");
