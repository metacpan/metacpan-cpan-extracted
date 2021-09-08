#!/usr/bin/env perl

use strict;
use warnings;

use DDP;
use MIDI::RtMidi::FFI::Device;
my $in = MIDI::RtMidi::FFI::Device->new( type => 'in', name => 'test_events' );
$in->open_port_by_name( qr/loopmidi/i );

print "Press Ctrl-C to exit\n";
while (1) {
    if ( my $event = $in->get_event ) {
        p $event;
        print "Press Ctrl-C to exit\n";
    }
}
