#!/usr/bin/env perl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || 'joystick';
my $output_name = shift || 'usb';
my $filter_name = shift || 'single';

my $control = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);

$filter->control(1); # CC#01 = mod-wheel
# $filter->value(0);
# $filter->range_bottom(0);
# $filter->range_top(70);
# $filter->range_step(2);
# $filter->time_step(0.15);
# $filter->step_up(10);
# $filter->step_down(2);

my $method = "curry::$filter_name";
$control->add_filter($filter_name, all => $filter->$method);

$control->run;

# ...and now trigger a MIDI message!
