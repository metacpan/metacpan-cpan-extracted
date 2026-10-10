#!/usr/bin/env perl

# Open and start an available system midi port.

use v5.36;
use Data::Dumper::Compact qw(ddc);
use IO::Async::Loop ();
use IO::Async::Timer::Periodic ();
use MIDI::RtMidi::FFI::Device ();
use MIDI::RtMidi::Util qw(out_port stop_device stop_all_notes);

my $bpm  = shift || 60;
my $port = shift || 'usb';

my $divisions_beat  = 4;
my $clocks_per_beat = 6 * $divisions_beat; # PPQN
my $clock_interval  = 60 / $bpm / $clocks_per_beat;

my $midi_out = out_port($port);
$midi_out->start;

$SIG{INT} = sub {
    say "\nStop";
    stop_device($midi_out);
    stop_all_notes($midi_out);
    exit;
};

my $loop = IO::Async::Loop->new;

my $timer = IO::Async::Timer::Periodic->new(
    interval => $clock_interval,
    on_tick  => sub {
        $midi_out->clock;
    },
);

$timer->start;
$loop->add($timer);
$loop->run;