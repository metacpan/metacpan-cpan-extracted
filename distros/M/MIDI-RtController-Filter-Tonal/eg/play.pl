#!/usr/bin/env perl
use strict;
use warnings;

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::Tonal ();
use Time::HiRes qw(usleep);

my $input_name  = shift || 'tempopad'; # midi controller device
my $output_name = shift || 'fluid';    # fluidsynth
my $filter_name = shift || 'walk_tone';

my $rtc = MIDI::RtController->new(
    input  => $input_name,
    output => $output_name,
    verbose => 1,
);

my $rtf = MIDI::RtController::Filter::Tonal->new(rtc => $rtc);

$rtc->send_it(['patch_change', $rtf->channel, 2]);

$rtf->feedback(4);
$rtf->delay(0.5);
# $rtf->factor(1.5);

my $method = "curry::$filter_name";
$rtc->add_filter($filter_name, [qw(note_on note_off)], $rtf->$method);

# my $micros = 500_000;
# $rtf->$filter_name('system', 0, ['note_on', $rtf->channel, 60, 100]);
# usleep($micros);
# $rtf->$filter_name('system', 0, ['note_off', $rtf->channel, 60, 100]);

$rtc->run;
