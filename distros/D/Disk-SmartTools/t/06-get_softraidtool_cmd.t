#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

use IPC::Cmd qw(can_run);

#======================================#
#         get_softraidtool_cmd         #
#======================================#

my $cmd_path = can_run('softraidtool');
SKIP: {
    skip "The softraidtool command is not installed on this system", 2
        unless ( defined $cmd_path );
    skip "The softraidtool command is MacOS only.", 2 unless ( is_mac() );
    my $softraidtool_cmd = get_softraidtool_cmd();
    ok( file_executable($softraidtool_cmd),
        "get_softraidtool_cmd - softraidtool cmd is executable." );
    is( $softraidtool_cmd, $cmd_path, "get_softraidtool_cmd finds the command." );
}

done_testing;
