#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#            is_drive_smart            #
#======================================#
ok( ( not is_drive_smart('/dev/null') ),
    "is_drive_smart - /dev/null should not be smart." );

done_testing;
