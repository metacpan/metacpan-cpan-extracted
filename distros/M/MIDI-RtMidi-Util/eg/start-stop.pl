#!/usr/bin/env perl

# Open and start an available system midi port. Stop with CTRL+C.

use v5.40;
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

my $loop = IO::Async::Loop->new;

$loop->watch_signal(INT => sub {
    say "\nStop";
    try {
        stop_device($device);
        stop_all_notes($device);
    }
    catch ($e) {
        warn "Can't halt MIDI out device '$device': $e\n";
    }
    $loop->stop;
});

my $timer = IO::Async::Timer::Periodic->new(
    interval => $clock_interval,
    on_tick  => sub {
        $midi_out->clock;
        say 'Hello!';
    },
);

$timer->start;
$loop->add($timer);
$loop->run;