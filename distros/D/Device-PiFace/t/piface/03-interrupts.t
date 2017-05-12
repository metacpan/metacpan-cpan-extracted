#!/usr/bin/env perl
use strict;
use warnings;
use Device::PiFace ':piface_constants';
use Test::More;

my $piface = Device::PiFace->new (hw_addr => $ENV{PIFACE_HARDWARE_ADDRESS} // 0);
$piface->enable_interrupts()
    or plan skip_all => "can't enable interrupts";

diag 'Press any button on your PiFace board within 5 seconds...';
my ($success, $value) = $piface->wait_for_input (timeout => 5000);

plan skip_all => 'timeout' if $success == R_TIMEOUT;

plan tests => 3;

is $success, 1, 'wait_for_input succeeded';
is $value & 255, $value, '0 <= $value <= 255';
