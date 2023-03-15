#!/usr/bin/env perl

use v5.36.0;

use MIDI::RtMidi::FFI::Device;

my $in = MIDI::RtMidi::FFI::Device->new( type => 'in', name => 'in' );
my $out = MIDI::RtMidi::FFI::Device->new( type => 'out', name => 'out' );
$out->open_virtual_port( 'glitchy device' );
$in->open_port_by_name( 'glitchy device' );

# Oh no, something's about to go wrong - no 'note off' sent
$out->send_event( note_on => 0x00, 0x7f, 0x7f );
sleep 1;

# ...better hit the panic button
for my $channel ( 0x00..0x0f ) {
    for my $note ( 0x00..0x7f ) {
        $out->send_event( note_off => $channel, $note, 0x00 );
    }
}
