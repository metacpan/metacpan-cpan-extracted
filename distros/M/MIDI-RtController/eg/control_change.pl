#!/usr/bin/env perl

# Iterate up and down through the modwheel (CC#01) range.

use strict;
use warnings;

use MIDI::RtController ();
use Iterator::Breathe ();

my $in  = shift || 'pad'; # Synido TempoPAD Z-1
my $out = shift || 'usb'; # USB MIDI Interface

my $rtc = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

my $it = Iterator::Breathe->new(
    top    => 127,
    bottom => 0,
    # step   => 4,
);

while (1) {
    $it->iterate;
    $rtc->send_it([ 'control_change', 0, 1, $it->i ]);
    sleep 1;
}

$rtc->run;
