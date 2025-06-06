#!/usr/bin/env perl

# Iterate up and down through the modwheel (CC#01) range.

use strict;
use warnings;

use MIDI::RtController ();
use Iterator::Breathe ();
use Time::HiRes qw(usleep);

# nb: The input device is not actually used for this example,
# but is required by the module, nonetheless.
my $in  = shift || 'pad'; # Synido TempoPAD Z-1
# output MIDI device
my $out = shift || 'usb'; # USB MIDI Interface

my $channel = 0;
my $control = 1;

# set-up the controllers
my $rtc = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

# set-up the "breathing" iterator
my $it = Iterator::Breathe->new(
    bottom => 0,
    top    => 127,
    # step   => 4,
);

# send a control-change message every usleep number of microseconds
while (1) {
    $it->iterate;
    $rtc->send_it([ 'control_change', $channel, $control, $it->i ]);
    usleep 250_000; # 1_000_000 microseconds = 1 second
}

# set the controls for the heart of the sun
$rtc->run;
