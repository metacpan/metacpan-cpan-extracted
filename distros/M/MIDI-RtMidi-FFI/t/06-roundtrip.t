use strict;
use warnings;

use Test2::V0;

use MIDI::RtMidi::FFI::Device;
my $dev = RtMidiOut->new( api_name => 'dummy' );

my $msgs = [
    [ note_on             => 0x05, 0x7F, 0x3A ],
    [ note_off            => 0x03, 0x7F, 0x00 ],
    [ key_after_touch     => 0x05, 0x7F, 0x7A ],
    [ control_change      => 0x0B, 0x06, 0xB6 ],
    [ patch_change        => 0x03, 0x3A ],
    [ channel_after_touch => 0x0A, 0x7A ],
    [ pitch_wheel_change  => 0x0F, 0x1B13 ],
    [ sysex_f0            => "Hello, world!" . chr(0xF7) ],
    [ timecode            => 0x02, 0x01, 0x2F, 0x1E, 0x13 ],
    [ 'clock' ],
    [ 'start' ],
    [ 'continue' ],
    [ 'stop' ],
    [ 'active_sensing' ],
    [ 'system_reset' ],
];

sub round_trip {
    my ( $msg ) = @_;
    scalar $dev->decode_message( $dev->encode_message( @{ $msg } ) );
}

for my $msg ( @{ $msgs } ) {
    is round_trip( $msg ), $msg, "Round-trip decode OK for $msg->[0]";
}

undef $dev;

done_testing;
