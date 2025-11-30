#!/usr/bin/env perl

use lib 'lib';
use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_os is_linux is_mac);
use Dev::Util::File  qw(file_executable);
use Disk::SmartTools qw(:all);

#======================================#
#             disk_prefix              #
#======================================#

my $expected_disk_prefix;
my $OS = get_os();
if ( $OS eq 'Linux' ) {
    $expected_disk_prefix = '/dev/sd';
}
elsif ( $OS eq 'Darwin' ) {
    $expected_disk_prefix = '/dev/disk';
}
else {
    croak "Unsupported system\n";
}

my $prefix = get_disk_prefix();
is( $prefix, $expected_disk_prefix,
    "get_disk_prefix - the correct disk prefix returns true." );

done_testing;

