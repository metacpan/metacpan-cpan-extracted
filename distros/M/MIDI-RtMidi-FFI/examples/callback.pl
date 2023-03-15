#!/usr/bin/env perl

use v5.36;

use IO::Async::Timer::Periodic;
use IO::Async::Routine;
use IO::Async::Channel;
use IO::Async::Loop;
use Future::AsyncAwait;
use MIDI::RtMidi::FFI::Device;
use Time::HiRes qw/ gettimeofday tv_interval /;

my $loop = IO::Async::Loop->new;
my $midi_ch = IO::Async::Channel->new;

my $midi_rtn = IO::Async::Routine->new(
    channels_out => [ $midi_ch ],
    code => sub {
        my $midi_in = MIDI::RtMidi::FFI::Device->new( type => 'in' );
        $midi_in->open_port_by_name( qr/LKMK3/i ); # LaunchKey Mk 3

        $midi_in->set_callback(
            sub( $ts, $msg, $data = undef ) {
                my $t0 = [ gettimeofday ];
                $midi_ch->send( [ $t0, $ts, $msg ] );
            }
        );

        sleep;
    }
);
$loop->add( $midi_rtn );

$SIG{TERM} = sub { $midi_rtn->kill('TERM') };

async sub process_midi_events {
    while ( my $event = await $midi_ch->recv ) {
        say "recv took " . tv_interval( $event->[0] ) . "s";
        say "ts " . $event->[1] . "s";
        say unpack 'H*', $event->[2];
    }
}

my $tick = 0;
$loop->add( IO::Async::Timer::Periodic->new(
    interval => 1,
    on_tick => sub { say "Tick " . $tick++; },
)->start );

$loop->await( process_midi_events );
