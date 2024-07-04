#!/usr/bin/env perl

use strict;
use warnings;
use v5.36;
use MIDI::RtMidi::FFI::Device;

my $midi_in = RtMidiIn->new;
$midi_in->open_port_by_name( qr/LKMK3/i ); # LaunchKey Mk 3

$midi_in->set_callback_decoded(
    sub { say join "\n", ( $_[0], $_[2]->@* ) }
);

sleep;

