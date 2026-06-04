#!/usr/bin/env perl

use v5.36;
use MIDI::RtController ();

my $output_name = shift || 'Trinity';

my $controller = MIDI::RtController->new(
    input   => $output_name,
    output  => $output_name,
    verbose => 1,
);

for my $val (0 .. 127) {
    $controller->send_it(['control_change', 1, 78, $val]);
    sleep(1);
}