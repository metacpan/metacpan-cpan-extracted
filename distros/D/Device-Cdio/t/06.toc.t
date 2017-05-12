#!/usr/bin/env perl
#Test functioning of cdrdao image routines

use strict;
use warnings;

use lib '../lib';
use blib;

use Device::Cdio::Device;
use Test::More tests => 12;
note "Test cdrdao image routines";

## TOC reading needs to be done in the directory where the
## TOC/BIN files reside.


if (-d "data") {
    chdir "data" ;
} elsif (-d "../data") {
    chdir "../data" ;
}

my $tocfile = "cdda.toc";
my $device  = Device::Cdio::Device->new(-source=>$tocfile, 
					-driver_id=>$perlcdio::DRIVER_CDRDAO);
my ($vendor, $model, $revision, $drc)  = $device->get_hwinfo();
## FIXME:
## ok($perlcdio::DRIVER_OP_SUCCESS == $drc, "get_hwinfo ok");
ok(defined($vendor) && 'libcdio' eq $vendor, "get_hwinfo vendor");
ok(defined($model) && 'cdrdao' eq $model, "get_hwinfo cdrdao");
# Test known values of various access parameters:
# access mode, driver name via string and via driver_id
# and cue name
my $result = $device->get_arg("access-mode");
ok($result eq 'image', 'get_arg("access_mode")');
$result = $device->get_driver_name();
ok(defined($result) && $result eq 'CDRDAO', 'get_driver_name');
$result = $device->get_driver_id();
ok(defined($result) && $result eq $perlcdio::DRIVER_CDRDAO, 'get_driver_id');
$result = $device->get_arg("source");
ok(defined($result) && $result eq $tocfile, 'get_arg("source")');
$result = $device->get_media_changed();
ok(!$result, "tocfile: get_media_changed");
# Test getting is_tocfile
$result = Device::Cdio::is_tocfile($tocfile);
ok(defined($result) && $result, "is_tocfile(tocfile)");
$result = Device::Cdio::is_nrg($tocfile);
ok(defined($result) && !$result, "is_nrgfile(tocfile)");
$result = Device::Cdio::is_device($tocfile);
ok(defined($result) && !$result, "is_device(tocfile)");
$drc = $device->set_blocksize(2048);
ok($perlcdio::DRIVER_OP_UNSUPPORTED == $drc, "set blocksize");
$drc = $device->set_speed(5);
ok($perlcdio::DRIVER_OP_UNSUPPORTED == $drc, "set speed");
$device->close();
