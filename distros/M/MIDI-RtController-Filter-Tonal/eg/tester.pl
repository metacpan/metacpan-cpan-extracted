#!/usr/bin/env perl
use strict;
use warnings;

# PERL_FUTURE_DEBUG=1 perl eg/tester.pl

use curry;
use Future::IO::Impl::IOAsync;
use MIDI::RtController ();
use MIDI::RtController::Filter::Tonal ();

my $input_name  = shift || 'tempopad'; # midi controller device
my $output_name = shift || 'fluid';    # fluidsynth
my $filter_name = shift || 'pedal_tone';

my $rtc = MIDI::RtController->new(
    input  => $input_name,
    output => $output_name,
    verbose => 1,
);

my $rtf = MIDI::RtController::Filter::Tonal->new(rtc => $rtc);
# $rtf->feedback(4);

my $method = "curry::$filter_name";
$rtc->add_filter($filter_name, [qw(note_on note_off)], $rtf->$method);

$rtc->run;
