#!/usr/bin/env perl

# fluidsynth -a coreaudio -m coremidi -g 2.0 ~/Music/FluidR3_GM.sf2
# PERL_FUTURE_DEBUG=1 perl rtmidi-dual.pl

use v5.36;

use MIDI::RtController ();

my $input_name_1 = shift || 'joystick'; # midi controller device
my $input_name_2 = shift || 'tempopad'; # midi controller device
my $output_name  = shift || 'fluid';    # fluidsynth output

my $rtc_1 = MIDI::RtController->new(
    input   => $input_name_1,
    output  => $output_name,
    verbose => 1,
);

my $rtc_2 = MIDI::RtController->new(
    input    => $input_name_2,
    loop     => $rtc_1->loop,
    midi_out => $rtc_1->midi_out,
    verbose  => 1,
);

$rtc_2->run;
