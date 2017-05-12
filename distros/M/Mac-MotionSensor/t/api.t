use strict;
use warnings;
use Test::More qw/no_plan/;
use_ok('Mac::MotionSensor');

my $sensor =  Mac::MotionSensor->new;

isa_ok($sensor, 'Mac::MotionSensor');

can_ok($sensor,
    qw/x y z
    raw_x
    raw_x
    raw_z
    type
    /
);

