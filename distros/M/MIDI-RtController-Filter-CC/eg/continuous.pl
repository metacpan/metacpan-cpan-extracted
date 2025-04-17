#!/usr/bin/env perl

use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();
use Object::Destroyer ();

my $in  = shift || '49 midi'; # keyboard controller
my $out = shift || 'usb'; # midi output

my @filters = (
    { # cutoff
        port => '49 midi',
        event => 'control_change',
        control => 74,
        trigger => 35,
    },
    { # resonance
        port => '49 midi',
        event => 'control_change',
        control => 71,
        trigger => 36,
    },
);

# open the inputs
my $control = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

MIDI::RtController::Filter::CC::add_filters(\@filters, { $in => $control });

$control->run;

# ...and now trigger a MIDI message!

# XXX maybe needed?
END: {
    Object::Destroyer->new($control, 'delete');
}
