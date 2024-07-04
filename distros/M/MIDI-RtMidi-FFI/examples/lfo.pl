#!/usr/bin/env perl

# Bit of a stress test for 14-bit CC

use strict;
use warnings;

use constant {
    FREQUENCY   => 1,
    SAMPLE_RATE => 2000,
    BIT_DEPTH   => 14,
};

use Time::HiRes qw/ time usleep /;
use Math::Trig ':pi';
use MIDI::RtMidi::FFI::Device;

my $out = RtMidiOut->new( qw/ 14bit_mode midi / );

print "Press return to start LFO..."; <STDIN>;
print "Press ^C to stop LFO...\n";

if ( $^O eq 'MSWin32' ) {
    $out->open_port_by_name( qr/loopmidi/i );
}
else {
    $out->open_virtual_port( 'LFO' );
}

my $max = ( 2 ** BIT_DEPTH ) / 2;
my $sleep = 1_000_000 / SAMPLE_RATE;
my $now = time;

while (1) {
    my $sample = ( sin( pi2 * FREQUENCY * ( time - $now ) ) + 1 ) * $max;
    $out->cc( 0x00, 0x00, $sample );
    usleep( $sleep );
}
