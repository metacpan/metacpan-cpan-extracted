#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use LightWaveRF;

my $lw = new LightWaveRF;

ok($lw->register('D1', 'R1', "LivingRoomLight"), "Registered LivingRoomLight");
is(scalar(keys(%{$lw->_devices})), 1, "1 Device registered");

ok($lw->register('D1', 'R2', "DiningRoomLight"), "Registered DiningRoomLight");
is(scalar(keys(%{$lw->_devices})), 2, "2 Devices registered");

ok($lw->on('LivingRoomLight') == 1, "Sent signal to switch LivingRoomLight on");
ok($lw->off('LivingRoomLight') == 1, "Sent signal to switch LivingRoomLight off");

done_testing();