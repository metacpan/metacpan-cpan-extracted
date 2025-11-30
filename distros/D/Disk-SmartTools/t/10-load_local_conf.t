#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::File qw(dir_suffix_slash);

use Disk::SmartTools qw(:all);

use FindBin qw($RealBin);

# set home so tests get the rc file locally instead of the real $HOME
local $ENV{ HOME } = dir_suffix_slash($RealBin);

my $disk_info_athos_ref = {
                            'disks'     => [ 'b', 'c', 'd', 'e', 'f', 'g', 'h' ],
                            'has_raid'  => 1,
                            'has_disks' => 1,
                            'rdisks'    => [
                                          '1/1/1', '1/2/1', '1/3/1', '1/4/1',
                                          '1/5/1', '1/6/1', '1/7/1', '1/8/1'
                                        ],
                            'rdisk_prefix' => '/dev/sda'
                          };

my $disk_info_porthos_ref = { 'disks' => [ 0, 4, 5, 6, 7 ] };

my $disk_info_aramis_ref = { 'has_raid'     => 1,
                             'has_disks'    => 1,
                             'rdisk_prefix' => '/dev/sda',
                             'rdisks'       => [ '00', '01', '02', '03' ],
                             'disks'        => ['a']
                           };

my $local_config_athos_ref = load_local_config('athos');
is( $local_config_athos_ref, $disk_info_athos_ref,
    "Local host athos config loaded" );

my $local_config_porthos_ref = load_local_config('porthos');
is( $local_config_porthos_ref, $disk_info_porthos_ref,
    "Local host porthos config loaded" );

my $local_config_aramis_ref = load_local_config('aramis');
is( $local_config_aramis_ref, $disk_info_aramis_ref,
    "Local host aramis config loaded" );

done_testing;
