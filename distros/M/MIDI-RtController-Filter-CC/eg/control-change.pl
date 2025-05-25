#!/usr/bin/env perl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || 'joystick';
my $output_name = shift || 'usb';
my $filter_name = shift || 'breathe';

my $controller = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::CC->new(rtc => $controller);

# $controller->send_it(['patch_change', $filter->channel, 6]);

# $filter->trigger(25);
$filter->control(1); # CC#01 = mod-wheel
# $filter->value(0);
# $filter->range_bottom(0);
# $filter->range_top(70);
# $filter->range_step(2);
# $filter->time_step(60 / (60 * 24)); # seconds / (bpm * ppqn) <- for clock_it
# $filter->step_up(10);
# $filter->step_down(2);

my $method = "curry::$filter_name";
$controller->add_filter($filter_name, all => $filter->$method);

$controller->run;

# ...and now trigger a MIDI message!

END {
    $filter->halt(1);
}
