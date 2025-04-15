#!/usr/bin/env perl

use MIDI::RtController ();

my $input_names = shift || 'keyboard,pad,joystick'; # midi controller devices
my $output_name = shift || 'usb'; # midi output

my $verbose = 1;

my @inputs = split /,/, $input_names;

my $controllers = MIDI::RtController::open_controllers($input_names, $output_name, $verbose);

$controllers->{ $inputs[0] }->run;
