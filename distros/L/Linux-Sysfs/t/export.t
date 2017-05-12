#!perl

use strict;
use warnings;
use Test::More tests => 13;
use Linux::Sysfs qw(:all);

ok( length $FSTYPE_NAME, 'FSTYPE_NAME' );
ok( length $PROC_MNTS, 'PROC_MNTS' );
ok( length $BUS_NAME, 'BUS_NAME' );
ok( length $CLASS_NAME, 'CLASS_NAME' );
ok( length $BLOCK_NAME, 'BLOCK_NAME' );
ok( length $DEVICES_NAME, 'DEVICES_NAME' );
ok( length $DRIVERS_NAME, 'DRIVERS_NAME' );
ok( length $MODULE_NAME, 'MODULE_NAME' );
ok( length $NAME_ATTRIBUTE, 'NAME_ATTRIBUTE' );
ok( length $MOD_PARM_NAME, 'MOD_PARM_NAME' );
ok( length $MOD_SECT_NAME, 'MOD_SECT_NAME' );
ok( length $UNKNOWN, 'UNKNOWN' );
ok( length $PATH_ENV, 'PATH_ENV' );
