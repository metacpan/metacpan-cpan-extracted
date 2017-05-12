#!perl

use strict;
use warnings;
use Test::More tests => 13;
use Linux::Sysfs;

ok( length $Linux::Sysfs::FSTYPE_NAME, 'FSTYPE_NAME' );
ok( length $Linux::Sysfs::PROC_MNTS, 'PROC_MNTS' );
ok( length $Linux::Sysfs::BUS_NAME, 'BUS_NAME' );
ok( length $Linux::Sysfs::CLASS_NAME, 'CLASS_NAME' );
ok( length $Linux::Sysfs::BLOCK_NAME, 'BLOCK_NAME' );
ok( length $Linux::Sysfs::DEVICES_NAME, 'DEVICES_NAME' );
ok( length $Linux::Sysfs::DRIVERS_NAME, 'DRIVERS_NAME' );
ok( length $Linux::Sysfs::MODULE_NAME, 'MODULE_NAME' );
ok( length $Linux::Sysfs::NAME_ATTRIBUTE, 'NAME_ATTRIBUTE' );
ok( length $Linux::Sysfs::MOD_PARM_NAME, 'MOD_PARM_NAME' );
ok( length $Linux::Sysfs::MOD_SECT_NAME, 'MOD_SECT_NAME' );
ok( length $Linux::Sysfs::UNKNOWN, 'UNKNOWN' );
ok( length $Linux::Sysfs::PATH_ENV, 'PATH_ENV' );
