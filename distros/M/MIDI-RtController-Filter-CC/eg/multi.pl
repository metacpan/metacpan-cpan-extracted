#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || 'joystick';
my $output_name = shift || 'usb';

my $control = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my %filters = (
    1 => { # mod-wheel
        type => 'scatter',
        time_step => 0.25,
    },
    # 13 => { # delay time
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 100,
    # },
    22 => { # noise
        type => 'stair_step',
        time_step => 0.5,
        range_bottom => 0,
        range_top => 80,
    },
    # 26 => { # filter e.g. release
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 127,
    # },
    # 77 => {  # oscillator 1 waveform
        # type => 'single',
        # value => 0, # 0: sawtooth
    # },
);

for my $ctrl (keys %filters) {
    my %params = $filters{$ctrl}->%*;
    my $type = delete $params{type};
    my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);
    $filter->control($ctrl);
    for my $param (keys %params) {
        $filter->$param($params{$param});
    }
    my $method = "curry::$type";
    $control->add_filter($type, ['all'], $filter->$method);
}

$control->run;

# ...and now trigger a MIDI message!
