#!/usr/bin/perl

# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX                    ();
use Filesys::POSIX::ReducedPrivileges ();
use Filesys::POSIX::Bits;

use File::Temp ();
use Fcntl;

use Test::More;

BEGIN {
    if ( $> == 0 ) {
        plan tests => 13;
    }
    else {
        plan skip_all => 'Privilege droppping tests require root';
    }
}

use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 );
chmod( 0755, $tmpdir );

my %files = (
    'foo'          => 'file',
    'bar'          => 'dir',
    'bar/baz'      => 'dir',
    'bar/boo'      => 'dir',
    'bar/boo/cats' => 'file'
);

foreach ( sort keys %files ) {
    my $path = "$tmpdir/$_";

    if ( $files{$_} eq 'file' ) {
        sysopen( my $fh, $path, O_CREAT );
        close($fh);
    }
    elsif ( $files{$_} eq 'dir' ) {
        mkdir($path);
    }
}

my $fs = Filesys::POSIX->new( Filesys::POSIX::ReducedPrivileges->new, uid => 99, gid => 99, 'path' => $tmpdir );

foreach ( sort keys %files ) {
    my $inode = $fs->stat($_);

    if ( $files{$_} eq 'file' ) {
        ok( $inode->file, "Filesys::POSIX::ReducedPrivileges sees $_ as a file" );
        ok(
            $inode->{'size'} == 0,
            "Filesys::POSIX::ReducedPrivileges sees $_ as a 0 byte file"
        );
    }
    elsif ( $files{$_} eq 'dir' ) {
        ok( $inode->dir, "Filesys::POSIX::ReducedPrivileges sees $_ as a directory" );
    }
}

throws_errno_ok {
    Filesys::POSIX->new( Filesys::POSIX::ReducedPrivileges->new, uid => 99, gid => 99 );
}
&Errno::EINVAL, "Filesys::POSIX::ReducedPrivileges->init() dies when no path is specified";

throws_errno_ok {
    Filesys::POSIX->new( Filesys::POSIX::ReducedPrivileges->new, uid => 99, gid => 99, 'path' => '/dev/null' );
}
&Errno::ENOTDIR, "Filesys::POSIX::ReducedPrivileges->init() dies when special is not a directory";

TODO: {
    local $TODO = "Rename failures currently not implemented in Filesys::POSIX::Real";
    dies_ok {
        $fs->rename( 'foo', 'bleh' );
    }
    "Filesys::POSIX->rename() fails to renaming file in root owned directory";
}
ok( -e "$tmpdir/foo",   "Original filename remains after failed rename" );
ok( !-e "$tmpdir/bleh", "New filename was not created by failed rename" );
