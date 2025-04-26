#!/usr/bin/env perl

use curry;
use Future::IO::Impl::IOAsync;
use MIDI::RtController ();
use MIDI::RtController::Filter::Drums ();

my $input_name  = shift || 'pad';   # midi controller device
my $output_name = shift || 'fluid'; # fluidsynth

my $controller = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::Drums->new(rtc => $controller);

$filter->phrase(\&my_phrase);
$filter->bars(8);
$filter->trigger(99);

$controller->add_filter('drums', note_on => $filter->curry::drums);

$controller->run;

sub my_phrase {
    my (%args) = @_;
    $args{drummer}->metronome3;
}
