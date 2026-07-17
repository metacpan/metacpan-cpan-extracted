#!/usr/bin/env perl

use v5.36;

use Future::IO;
use Future::AsyncAwait;
use MIDI::RtMidi::FFI::Device;
use MIDI::Stream::Decoder;

my $midi_in = RtMidiIn->new();
$midi_in->open_port_by_name( qr/sz|lkmk3/i );
my $fh = $midi_in->get_fh;

my $decoder = MIDI::Stream::Decoder->new;
$decoder->attach_callback( all => sub( $event ) {
    say join ' ', $event->dt, $event->as_arrayref->@*
} );

async sub msg {
    my $size = $midi_in->bufsize;
    while ( my $midi_bytes = await Future::IO->read( $fh, $size ) ) {
        $decoder->decode( $midi_bytes );
    }
}

async sub tick {
    my $tick = 0;
    while ( 1 ) {
        await Future::IO->sleep( 1 );
        say "Tick " . $tick++;
    }
}

Future->wait_all( tick, msg )->get;
