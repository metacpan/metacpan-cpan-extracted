#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#           get_diskutil_cmd           #
#======================================#

if ( is_mac() ) {
    my $diskutil_cmd = get_diskutil_cmd();
    ok( file_executable($diskutil_cmd),
        "get_diskutil_cmd - diskutil cmd is executable." );
}
else {
    pass("Not a macos system");
}

done_testing;
