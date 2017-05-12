#!/usr/bin/env perl
# Test that we have image drivers

use strict;
use warnings;
use lib '../lib';
use blib;

use Device::Cdio::Device;
use Test::More;
note "Test we have image drivers";

my $result = Device::Cdio::have_driver('CDRDAO');
ok($result, "Have cdrdrao driver via string");
$result = Device::Cdio::have_driver($perlcdio::DRIVER_CDRDAO);
ok($result, "Have cdrdrao driver via driver_id");
$result = Device::Cdio::have_driver('NRG');
ok($result, "Have NRG driver via string");
$result = Device::Cdio::have_driver($perlcdio::DRIVER_NRG);
ok($result, "Have NRG driver via driver_id");
$result = Device::Cdio::have_driver('BIN/CUE');
ok($result, "Have BIN/CUE driver via string");
$result = Device::Cdio::have_driver($perlcdio::DRIVER_BINCUE);
ok($result, "Have BIN/CUE driver via driver_id");
done_testing();
