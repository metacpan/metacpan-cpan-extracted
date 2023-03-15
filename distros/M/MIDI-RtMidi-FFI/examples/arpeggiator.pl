#!/usr/bin/env perl

use strict;
use warnings;

use IO::Async::Timer::Periodic;
use IO::Async::Loop;
use MIDI::RtMidi::FFI::Device;

my $loop = IO::Async::Loop->new;

my $out = MIDI::RtMidi::FFI::Device->new( name => 'otr arp' );
$out->open_port_by_name( qr/(?:vcv|sunvox|alsamodular|loopmidi)/i ); # <- your softsynth name here

# E2-G2-A2-G2-D3-C3-D3-E3
my @sequence = ( 40, 43, 45, 43, 50, 48, 50, 52 );
my $length = 0.09;

$loop->add( IO::Async::Timer::Periodic->new(
    interval => $length,
    reschedule => 'hard',
    on_tick => sub {
        $out->send_event(note_on => 0, $sequence[0], 0x7F);
        $out->send_event(note_off => 0, $sequence[-1], 0x7F);
        push @sequence, shift @sequence;
    },
)->start );

$SIG{'INT'} = $SIG{'TERM'} = sub { $out->send_event(note_off => 0, $_, 0x7F) for @sequence; exit 0; };

$loop->run;
