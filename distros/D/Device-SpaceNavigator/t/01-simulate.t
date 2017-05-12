#!perl -T

use strict;
use warnings;
use Test::More tests => 17;
use Device::SpaceNavigator;

my $spacenav = Device::SpaceNavigator->new();
ok(ref($spacenav), "Create object");

$spacenav->open('t/test_data/buttons_on');
$spacenav->update(0) for (1..2);
is($spacenav->left_button(), 1, 'Left button is pressed');
is($spacenav->right_button(), 1, 'Right button is pressed');

$spacenav->open('t/test_data/buttons_off');
$spacenav->update(1) for (1..2);
is($spacenav->left_button(), 0, 'Left button is released');
is($spacenav->right_button(), 0, 'Right button is released');

$spacenav->open('t/test_data/move');
$spacenav->update(1) for (1..6);
is($spacenav->x(),      442, 'X axe');
is($spacenav->y(),      443, 'Y axe');
is($spacenav->z(),      444, 'Z axe');
is($spacenav->pitch(),  445, 'Pitch');
is($spacenav->roll(),   446, 'Roll');
is($spacenav->yaw(),    447, 'Yaw');

$spacenav->open('t/test_data/move_negative');
$spacenav->update(1) for (1..6);
is($spacenav->x(),      -500, 'Negative X axes');
is($spacenav->y(),      -499, 'Negative Y axes');
is($spacenav->z(),      -498, 'Negative Z axes');
is($spacenav->pitch(),  -497, 'Negative pitch');
is($spacenav->roll(),   -496, 'Negative roll');
is($spacenav->yaw(),    -495, 'Negative yaw');

