#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#             get_raid_cmd             #
#======================================#

my $raid_cmd = get_raid_cmd();
SKIP: {
    skip "RAID command not found", 1 unless ( defined $raid_cmd );
    skip "Not a linux system",     1 unless ( is_linux() );
    if ( defined $raid_cmd ) { $raid_cmd =~ s| .*$||; }
    ok( file_executable($raid_cmd), "get_raid_cmd - raid cmd is executable." );
}

done_testing;
