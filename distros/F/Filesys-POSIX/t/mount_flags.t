# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX;
use Filesys::POSIX::Mem;
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 6 );
use Test::NoWarnings;

my $fs = Filesys::POSIX->new(
    Filesys::POSIX::Mem->new,
    'noatime' => 1,
    'noexec'  => 1,
    'nosuid'  => 1,
    'uid'     => 42,
    'gid'     => 42
);

#
# Note: These tests take advantage of an internal implementation detail in
# which the inode data is stored in a hash blessed into an Inode package.
#
# Since all inodes are held in their directory entries by reference,
# simply updating the reference returned by stat() suffices.
#
$fs->mkdir( 'foo', 04755 );
$fs->chown( 'foo', 500, 500 );

my $inode = $fs->stat('foo');
$inode->{'atime'} = 1234;

#
# This is the crucial part that would cause an atime update if 'noatime' were
# not specified.
#
$inode = $fs->stat('foo');

ok( $inode->{'atime'} == 1234, "Filesys::POSIX honors 'noatime' mount flag" );
ok(
    ( $inode->{'mode'} & $S_IX ) == 0,
    "Filesys::POSIX honors 'noexec' mount flag"
);
ok(
    ( $inode->{'mode'} & $S_ISUID ) == 0,
    "Filesys::POSIX honors 'nosuid' mount flag"
);
ok( $inode->{'uid'} == 42, "Filesys::POSIX honors 'uid' mount flag" );
ok( $inode->{'gid'} == 42, "Filesys::POSIX honors 'gid' mount flag" );
