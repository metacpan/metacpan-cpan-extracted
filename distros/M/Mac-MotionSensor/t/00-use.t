use strict;
use warnings;
use Test::More qw/no_plan/;
use_ok('Mac::MotionSensor');

my $type =  Mac::MotionSensor::detect_sms();
ok($type, 'detected motion sensor');
diag "type: $type";
diag "raw x: ".Mac::MotionSensor::_get_raw_x($type);
diag "raw y: ".Mac::MotionSensor::_get_raw_y($type);
diag "raw z: ".Mac::MotionSensor::_get_raw_z($type);
diag "x: ".Mac::MotionSensor::_get_x($type);
diag "y: ".Mac::MotionSensor::_get_y($type);
diag "z: ".Mac::MotionSensor::_get_z($type);

