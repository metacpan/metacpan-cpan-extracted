#!/usr/bin/env perl

use MIDI::RtController ();
use MIDI::RtController::Filter::Tonal ();
use Object::Destroyer ();

my $input_names = shift || 'keyboard,pad'; # CSV midi controller devices
my $output_name = shift || 'usb'; # midi output device
my $populate    = shift || 0; # use the 1st input for the filter port

my @inputs = split /,/, $input_names;
my $first = $inputs[0];

my @filters = get_filters();

if ($populate) {
    for my $filter (@filters) {
        $filter->{port} = $first;
    }
}

# open the inputs
my $controllers = MIDI::RtController::open_controllers(\@inputs, $output_name, 1);

MIDI::RtController::Filter::Tonal::add_filters(\@filters, $controllers);

$controllers->{$first}->run;

# ...and now trigger a MIDI message!

# XXX maybe needed?
END: {
    for my $i (keys %$controllers) {
        Object::Destroyer->new($controllers->{$i}, 'delete');
    }
}

sub get_filters {
    return (
        {   port => 'keyboard',
            event => [qw(note_on note_off)],
            type => 'delay_tone',
            delay => 0.1,
            feedback => 1,
        },
        {   port => 'keyboard',
            event => [qw(note_on note_off)],
            type => 'pedal_tone',
            delay => 0.25,
        },
    );
}
