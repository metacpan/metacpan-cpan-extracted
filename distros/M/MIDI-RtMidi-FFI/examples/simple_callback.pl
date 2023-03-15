#!/usr/bin/env perl

use strict;
use warnings;
use v5.36;
use MIDI::RtMidi::FFI::Device;

warn "create";
my $midi_in = MIDI::RtMidi::FFI::Device->new( type => 'in' );
warn "open";
$midi_in->open_port_by_name( qr/LKMK3/i ); # LaunchKey Mk 3

warn "callback";
$midi_in->set_callback_decoded(
    sub { say join "\n", ( $_[0], $_[2]->@* ) }
);

sleep;

