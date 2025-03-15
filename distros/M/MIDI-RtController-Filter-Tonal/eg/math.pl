#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/math.pl

use curry;
use Future::IO::Impl::IOAsync;
use MIDI::RtController ();
use MIDI::RtController::Filter::Math ();

my $input_name  = shift || 'tempopad'; # midi controller device
my $output_name = shift || 'fluid';    # fluidsynth

my $rtc = MIDI::RtController->new(
    input  => $input_name,
    output => $output_name,
);

my $rtf = MIDI::RtController::Filter::Math->new(rtc => $rtc);

$rtf->delay(0.15);
$rtf->feedback(6);

$rtc->add_filter('stair', [qw(note_on note_off)], $rtf->curry::stair_step);

$rtc->run;
