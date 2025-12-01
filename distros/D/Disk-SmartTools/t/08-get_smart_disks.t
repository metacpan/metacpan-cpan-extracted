#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;
use Test2::Tools::Compare qw(D);

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#           get_smart_disks            #
#======================================#

SKIP: {
    skip "The physical disks command is MacOS only.", 2 unless ( is_mac() );

    my @physical_disks = get_physical_disks();
    my @smart_disks    = get_smart_disks(@physical_disks);

    is( $smart_disks[0], D(),
        "get_smart_disks - Must have at least one smart disk" );

    ok(
        is_drive_smart( $smart_disks[0] ),
        "is_drive_smart - disk should be smart."
      );
}

done_testing;
