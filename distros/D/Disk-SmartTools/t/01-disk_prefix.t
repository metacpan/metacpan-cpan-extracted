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

SKIP: {
    skip "Unsported system, can't determine disk_prefix", 1
        unless (    is_linux()
                 || is_mac()
                 || is_freebsd()
                 || is_openbsd() );

    my $expected_disk_prefix;
    my $OS = get_os();
    if ( $OS eq 'Linux' ) {
        $expected_disk_prefix = '/dev/sd';
    }
    elsif ( $OS eq 'Darwin' ) {
        $expected_disk_prefix = '/dev/disk';
    }
    elsif ( $OS eq 'FreeBSD' ) {
        $expected_disk_prefix = '/dev/da';
    }
    elsif ( $OS eq 'OpenBSD' ) {
        $expected_disk_prefix = '/dev/sd';
    }
    else {
        $expected_disk_prefix = undef;
    }

    my $prefix = get_disk_prefix();
    is( $prefix, $expected_disk_prefix,
        "get_disk_prefix - the correct disk prefix returns true." );
}

done_testing;

