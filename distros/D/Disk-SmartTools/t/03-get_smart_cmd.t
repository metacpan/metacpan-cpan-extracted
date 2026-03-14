#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#            get_smart_cmd             #
#======================================#

my $smart_cmd = get_smart_cmd();
ok( file_executable($smart_cmd), "get_smart_cmd - smart cmd is executable." );

my $smart_version = get_smart_cmd_version();
ok( $smart_version =~ m|\d+\.\d+|,
    "get_smart_cmd_version - version is in the correct format." );

done_testing;
