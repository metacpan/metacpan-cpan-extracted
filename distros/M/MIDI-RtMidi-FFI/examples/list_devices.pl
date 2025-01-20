#!/usr/bin/env perl

use strict;
use warnings;

use MIDI::RtMidi::FFI::Device;

my $midi_in = RtMidiIn->new;

my $midi_out = RtMidiIn->new;

print "Input devices:\n";
$midi_in->print_ports;
print "\n";
print "Output devices:\n";
$midi_out->print_ports;

