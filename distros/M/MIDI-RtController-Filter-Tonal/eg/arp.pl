#!/usr/bin/env perl
use strict;
use warnings;

use curry;
use Future::IO::Impl::IOAsync;
use MIDI::RtController ();
use MIDI::RtController::Filter::Tonal ();

my $input_name  = shift || '49 MIDI'; # midi controller device
my $output_name = shift || 'fluid';   # fluidsynth
my $filter_name = shift || 'arp_tone';

my $rtc = MIDI::RtController->new(
    input  => $input_name,
    output => $output_name,
    verbose => 1,
);

my $rtf = MIDI::RtController::Filter::Tonal->new(
    rtc      => $rtc,
    arp_type => 'down',
    verbose  => 1,
);

$rtf->delay(0.2);

my $method = "curry::$filter_name";
$rtc->add_filter($filter_name, [qw(note_on note_off)], $rtf->$method);

$rtc->run;
