#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();
use Object::Destroyer ();

my $input_names = shift || 'keyboard,pad,joystick'; # midi controller devices
my $output_name = shift || 'usb'; # midi output

my %filters = (
    1 => { # mod-wheel
        port => 'pad',
        event => 'control_change', #[qw(note_on note_off)],
        type => 'breathe',
        time_step => 0.25,
    },
    # 13 => { # delay time
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 100,
    # },
    # 14 => { # waveform modulate
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.25,
        # range_bottom => 10,
        # range_top => 100,
    # },
    22 => { # noise
        port => 'joystick',
        type => 'ramp',
        time_step => 0.5,
        range_bottom => 0,
        range_top => 40,
    },
    # 26 => { # filter e.g. release
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 127,
    # },
    # 77 => {  # oscillator 1 waveform
        # port => 'joystick',
        # type => 'single',
        # value => 18, # 0: sawtooth, 18: square
    # },
);

my @inputs = split /,/, $input_names;
my $name = $inputs[0];

# open the inputs
my %controllers;
my $control = MIDI::RtController->new(
    input   => $name,
    output  => $output_name,
    verbose => 1,
);
$controllers{$name}->{rtc}    = $control;
$controllers{$name}->{filter} = MIDI::RtController::Filter::CC->new(
    rtc => $control
);
for my $i (@inputs[1 .. $#inputs]) {
    $controllers{$i}->{rtc} = MIDI::RtController->new(
        input    => $i,
        loop     => $control->loop,
        midi_out => $control->midi_out,
        verbose  => 1,
    );
    $controllers{$i}->{filter} = MIDI::RtController::Filter::CC->new(
        rtc => $controllers{$i}->{rtc}
    );
}

# add the filters
for my $cc (keys %filters) {
    my %params = $filters{$cc}->%*;
    my $port   = delete $params{port}  || $control->input;
    my $type   = delete $params{type}  || 'single';
    my $event  = delete $params{event} || 'all';
    my $filter = $controllers{$port}->{filter};
    $filter->control($cc);
    for my $param (keys %params) {
        $filter->$param($params{$param});
    }
    my $method = "curry::$type";
    $controllers{$port}->{rtc}->add_filter($type, $event => $filter->$method);
}

$control->run;

# ...and now trigger a MIDI message!

# XXX maybe needed?
END: {
    for my $i (@inputs) {
        Object::Destroyer->new($controllers{$i}->{rtc}, 'delete');
        Object::Destroyer->new($controllers{$i}->{filter}, 'delete');
    }
}
