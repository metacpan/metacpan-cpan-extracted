#!/usr/bin/env perl

use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || '49 MIDI';
my $output_name = shift || 'microKORG';

my $controller = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::CC->new(rtc => $controller);

$filter->channel(0);
$filter->trigger(2);

$controller->add_filter('program_change', all => $filter->curry::program_change);

$controller->run;