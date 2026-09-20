#!/usr/bin/env perl

use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $in        = shift || 'ez-ag'; # midi input controller
my $out       = shift || 'ez-ag'; # midi output
my $threshold = shift || 16;      # pivot point
my $direction = shift // 1;       # above=1, below=0

my $controller = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::CC->new(
    rtc     => $controller,
    verbose => 1,
);

$filter->trigger($threshold);

if ($direction) {
    $filter->step_up(1);
    $filter->step_down(0);
}
else {
    $filter->step_up(0);
    $filter->step_down(1);
}

my $filter_name = 'threshold';
my $method = "curry::$filter_name";
$controller->add_filter($filter_name, all => $filter->$method);

$controller->run;