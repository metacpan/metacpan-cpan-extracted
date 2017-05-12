# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

# -*- perl -*-

# t/bits.t - check bit conversion between Filesys::POSIX and Fcntl values

use Fcntl;
use Filesys::POSIX::Bits;
use Filesys::POSIX::Bits::System;

use Test::More;

my @FLAGS = (

    # Test the access modes
    [ 'O_RDONLY', $O_RDONLY, &Fcntl::O_RDONLY ],
    [ 'O_WRONLY', $O_WRONLY, &Fcntl::O_WRONLY ],
    [ 'O_RDWR',   $O_RDWR,   &Fcntl::O_RDWR ],

    # Test the individual flags (O_RDONLY included because an access mode is required)
    [
        'O_RDONLY | O_APPEND',
        $O_RDONLY | $O_APPEND,
        &Fcntl::O_RDONLY | &Fcntl::O_APPEND
    ],
    [
        'O_RDONLY | O_CREAT',
        $O_RDONLY | $O_CREAT,
        &Fcntl::O_RDONLY | &Fcntl::O_CREAT
    ],
    [
        'O_RDONLY | O_EXCL',
        $O_RDONLY | $O_EXCL,
        &Fcntl::O_RDONLY | &Fcntl::O_EXCL
    ],
    [
        'O_RDONLY | O_NOFOLLOW',
        $O_RDONLY | $O_NOFOLLOW,
        &Fcntl::O_RDONLY | &Fcntl::O_NOFOLLOW
    ],
    [
        'O_RDONLY | O_NONBLOCK',
        $O_RDONLY | $O_NONBLOCK,
        &Fcntl::O_RDONLY | &Fcntl::O_NONBLOCK
    ],
    [
        'O_RDONLY | O_TRUNC',
        $O_RDONLY | $O_TRUNC,
        &Fcntl::O_RDONLY | &Fcntl::O_TRUNC
    ],

    # Test an or-ed group
    [
        'O_WRONLY | O_APPEND | O_CREAT | O_NONBLOCK',
        $O_WRONLY | $O_APPEND | $O_CREAT | $O_NONBLOCK,
        &Fcntl::O_WRONLY | &Fcntl::O_APPEND | &Fcntl::O_CREAT | &Fcntl::O_NONBLOCK
    ],
);

my @MODES = (

    # Test permissions
    [ 'S_IRUSR', $S_IRUSR, &Fcntl::S_IRUSR ],
    [ 'S_IWUSR', $S_IWUSR, &Fcntl::S_IWUSR ],
    [ 'S_IXUSR', $S_IXUSR, &Fcntl::S_IXUSR ],
    [ 'S_IRGRP', $S_IRGRP, &Fcntl::S_IRGRP ],
    [ 'S_IWGRP', $S_IWGRP, &Fcntl::S_IWGRP ],
    [ 'S_IXGRP', $S_IXGRP, &Fcntl::S_IXGRP ],
    [ 'S_IROTH', $S_IROTH, &Fcntl::S_IROTH ],
    [ 'S_IWOTH', $S_IWOTH, &Fcntl::S_IWOTH ],
    [ 'S_IXOTH', $S_IXOTH, &Fcntl::S_IXOTH ],

    # Test sticky bits
    [ 'S_ISUID', $S_ISUID, &Fcntl::S_ISUID ],
    [ 'S_ISGID', $S_ISGID, &Fcntl::S_ISGID ],
    [ 'S_ISVTX', $S_ISVTX, &Fcntl::S_ISVTX ],

    # Test file types
    #[ 'S_IFWHT',  $S_IFWHT,  &Fcntl::S_IFWHT],
    [ 'S_IFIFO',  $S_IFIFO,  &Fcntl::S_IFIFO ],
    [ 'S_IFCHR',  $S_IFCHR,  &Fcntl::S_IFCHR ],
    [ 'S_IFDIR',  $S_IFDIR,  &Fcntl::S_IFDIR ],
    [ 'S_IFBLK',  $S_IFBLK,  &Fcntl::S_IFBLK ],
    [ 'S_IFREG',  $S_IFREG,  &Fcntl::S_IFREG ],
    [ 'S_IFLNK',  $S_IFLNK,  &Fcntl::S_IFLNK ],
    [ 'S_IFSOCK', $S_IFSOCK, &Fcntl::S_IFSOCK ],

    # Test an or-ed group
    [
        'S_IFREG | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH',
        $S_IFREG | $S_IRUSR | $S_IWUSR | $S_IRGRP | $S_IROTH,
        &Fcntl::S_IFREG | &Fcntl::S_IRUSR | &Fcntl::S_IWUSR | &Fcntl::S_IRGRP | &Fcntl::S_IROTH
    ],
);

my @WHENCE = (
    [ 'SEEK_SET', $SEEK_SET, &Fcntl::SEEK_SET ],
    [ 'SEEK_CUR', $SEEK_CUR, &Fcntl::SEEK_CUR ],
    [ 'SEEK_END', $SEEK_END, &Fcntl::SEEK_END ],
);

plan tests => @FLAGS + @MODES + @WHENCE;

foreach my $ref (@FLAGS) {
    my ( $name, $before, $after ) = @$ref;
    is(
        Filesys::POSIX::Bits::System::convertFlagsToSystem($before),
        $after, $name
    );
}

foreach my $ref (@MODES) {
    my ( $name, $before, $after ) = @$ref;
    is(
        Filesys::POSIX::Bits::System::convertModeToSystem($before),
        $after, $name
    );
}

foreach my $ref (@WHENCE) {
    my ( $name, $before, $after ) = @$ref;
    is(
        Filesys::POSIX::Bits::System::convertWhenceToSystem($before),
        $after, $name
    );
}
