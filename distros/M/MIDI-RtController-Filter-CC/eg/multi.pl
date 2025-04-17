#!/usr/bin/env perl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();
use Object::Destroyer ();

my $input_names = shift || 'keyboard,pad,joystick'; # midi controller devices
my $output_name = shift || 'usb'; # midi output

my @filters = (
    { # mod-wheel
        control => 1,
        port => 'pad',
        event => 'control_change', #[qw(note_on note_off)],
        trigger => 25,
        type => 'breathe',
        time_step => 0.25,
    },
    # { # delay time
        # port => 'joystick',
        # type => 'breathe',
        # control => 13,
        # trigger => 25,
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 100,
    # },
    { # noise down
        port => 'joystick',
        type => 'ramp_down',
        control => 22,
        trigger => 27,
        time_step => 0.5,
        range_bottom => 0,
        range_top => 40,
        initial_point => 40,
    },
    { # noise up
        port => 'joystick',
        type => 'ramp_up',
        control => 22,
        trigger => 26,
        time_step => 0.5,
        range_bottom => 0,
        range_top => 40,
    },
    # { # filter e.g. release
        # port => 'joystick',
        # type => 'breathe',
        # control => 26,
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 127,
    # },
    # { # oscillator 1 waveform
        # port => 'joystick',
        # control => 77,
        # trigger => 26,
        # value => 0, # 0: saw, 18: squ, 36: tri, 54: sin, 72 vox
    # },
    # { # waveform modulate
        # port => 'joystick',
        # type => 'breathe',
        # control => 14,
        # trigger => 27,
        # time_step => 0.25,
        # range_bottom => 10,
        # range_top => 100,
    # },
);

my @inputs = split /,/, $input_names;
my $name = $inputs[0];

# open the inputs
my $controllers = MIDI::RtController::open_controllers(\@inputs, $output_name, 1);

MIDI::RtController::Filter::CC::add_filters(\@filters, $controllers);

$controllers->{$name}->run;

# ...and now trigger a MIDI message!

# XXX maybe needed?
END: {
    for my $i (@$controllers) {
        Object::Destroyer->new($i, 'delete');
    }
}
