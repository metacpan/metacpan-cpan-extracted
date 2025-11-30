#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#          get_physical_disks          #
#======================================#
if ( is_mac() ) {
    my @physical_disks = get_physical_disks();
    is( $physical_disks[0], D(), "Must have at least one phsical disk" );
}
else {
    pass("Not a macos system");
}

done_testing;
