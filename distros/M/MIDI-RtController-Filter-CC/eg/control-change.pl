#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || 'joystick';
my $output_name = shift || 'usb';

my $control = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);

$filter->control(1); # CC#01 = mod-wheel
# $filter->range_bottom(10);
# $filter->range_top(100);
# $filter->range_step(2);
# $filter->time_step(125_000);
# $filter->step_up(10);
# $filter->step_down(2);

$control->add_filter('breathe', ['all'], $filter->curry::breathe);

# $control->add_filter('scatter', ['all'], $filter->curry::scatter);

# $control->add_filter('stair_step', ['all'], $filter->curry::stair_step);

$control->run;

# ...and now trigger a MIDI message!
