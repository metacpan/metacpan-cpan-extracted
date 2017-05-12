#!/usr/bin/env perl
# Test running miscellaneous operations
# No assumption about the CD-ROM drives is made, so
# we're just going to run operations and see that they
# don't crash.

use strict;
use warnings;
use lib '../lib';
use blib;

use Device::Cdio;
use Device::Cdio::Device;
use Test::More tests => 6;
note 'Test running miscellaneous operations';

my @drives = Device::Cdio::get_devices();
ok ( 1 , 'Device::Cdio::get_devices');
@drives = Device::Cdio::get_devices_with_cap($perlcdio::FS_MATCH_ALL);
ok ( 1 , 'Device::Cdio::get_devices_with_cap(perlcdio::FS_MATCH_ALL)');
my $dev = Device::Cdio::Device->new();
ok ( 1 , 'Device::Cdio::Device->new()');
$dev->open();
ok ( 1 , 'Device::Cdio::Device::open');
$dev->have_ATAPI();
ok ( 1 , 'Device::Cdio::Device::have_ATAPI');
$dev->get_media_changed();
ok ( 1 , 'Device::Cdio::Device::get_media_changed');
