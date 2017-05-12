# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX      ();
use Filesys::POSIX::Mem ();
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 18 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

{
    ok(
        Filesys::POSIX::Mem::Inode->new->{'mode'} == 0,
        "Filesys::POSIX::Mem::Inode->new() provides default mode of 0"
    );
}

my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

$fs->mkdir('foo');
ok(
    $fs->lstat('foo')->dir,
    'Filesys::POSIX::Inode->dir() reports true for directory inodes'
);

throws_errno_ok {
    $fs->touch('foo/bar');
    $fs->lstat('foo')->child( 'bar', 0644 );
}
&Errno::EEXIST, "Filesys::POSIX::Inode->child() throws an exception when requested member exists";

throws_errno_ok {
    $fs->lstat('foo')->readlink;
}
&Errno::EINVAL, "Filesys::POSIX::Inode->readlink() throws an exception on non-symlink inodes";

throws_errno_ok {
    $fs->lstat('foo')->symlink('bar');
}
&Errno::EINVAL, "Filesys::POSIX::Inode->symlink() throws an exception on non-symlink inodes";

$fs->symlink( 'foo', 'bar' );
ok(
    $fs->lstat('bar')->link,
    'Filesys::POSIX::Inode->link() reports true for symlink inodes'
);

my $fd = $fs->open( 'baz', $O_CREAT | $O_WRONLY );
ok(
    $fs->fstat($fd)->file,
    'Filesys::POSIX::Inode->file() reports true for regular file inodes'
);
$fs->close($fd);

$fs->chmod( 'baz', 0 );
ok(
    !$fs->lstat('baz')->readable,
    'Filesys::POSIX::Inode->readable() reports false when file is unreadable'
);
$fs->chmod( 'baz', 0644 );
ok(
    $fs->lstat('baz')->readable,
    'Filesys::POSIX::Inode->readable() reports true when file is readable'
);

$fs->chmod( 'baz', 0 );
ok(
    !$fs->lstat('baz')->writable,
    'Filesys::POSIX::Inode->writable() reports false when file is unwritable'
);
$fs->chmod( 'baz', 0644 );
ok(
    $fs->lstat('baz')->writable,
    'Filesys::POSIX::Inode->writable() reports true when file is writable'
);

$fs->chmod( 'baz', 0 );
ok(
    !$fs->lstat('baz')->executable,
    'Filesys::POSIX::Inode->executable() reports false when file is not executable'
);
$fs->chmod( 'baz', 0755 );
ok(
    $fs->lstat('baz')->executable,
    'Filesys::POSIX::Inode->executable() reports true when file is executable'
);

$fs->chmod( 'baz', 0 );
ok(
    !$fs->lstat('baz')->setuid,
    'Filesys::POSIX::Inode->setuid() reports false when file is not setuid'
);
$fs->chmod( 'baz', 04755 );
ok(
    $fs->lstat('baz')->setuid,
    'Filesys::POSIX::Inode->setuid() reports true when file is setuid'
);

$fs->chmod( 'baz', 0 );
ok(
    !$fs->lstat('baz')->setgid,
    'Filesys::POSIX::Inode->setgid() reports false when file is not setgid'
);
$fs->chmod( 'baz', 02755 );
ok(
    $fs->lstat('baz')->setgid,
    'Filesys::POSIX::Inode->setgid() reports true when file is setgid'
);
