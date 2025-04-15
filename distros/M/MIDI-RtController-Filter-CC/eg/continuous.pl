#!/usr/bin/env perl

use curry;
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

# add the filters
for my $params (@filters) {
    my $port   = delete $params->{port}  || $control->input;
    my $type   = delete $params->{type}  || 'single';
    my $event  = delete $params->{event} || 'all';
    my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);
    for my $param (keys %$params) {
        $filter->$param($params->{$param});
    }
    my $method = "curry::$type";
    $control->add_filter($type, $event => $filter->$method);
}

$control->run;

# ...and now trigger a MIDI message!

# XXX maybe needed?
END: {
    Object::Destroyer->new($control, 'delete');
}
