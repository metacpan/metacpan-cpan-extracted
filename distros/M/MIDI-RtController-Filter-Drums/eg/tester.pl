#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/tester.pl

use v5.36;

use curry;
use Future::IO::Impl::IOAsync;
use MIDI::RtController ();
use MIDI::RtController::Filter::Drums ();

my $input_name  = shift || 'tempopad'; # midi controller device
my $output_name = shift || 'fluid';    # fluidsynth

my $rtc = MIDI::RtController->new(
    input  => $input_name,
    output => $output_name,
);

my $rtfd = MIDI::RtController::Filter::Drums->new(rtc => $rtc);

add_filters('drums', $rtfd->curry::drums, 0);

$rtc->run;

sub add_filters ($name, $coderef, $types) {
    $types ||= [qw(note_on note_off)];
    $rtc->add_filter($name, $types, $coderef);
}
