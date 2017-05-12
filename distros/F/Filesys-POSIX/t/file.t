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

use Test::More ( 'tests' => 50 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

{
    my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

    $fs->mkdir('/mnt');
    $fs->mount( Filesys::POSIX::Mem->new, '/mnt' );

    ok(
        $fs->stat('/..') eq $fs->{'root'},
        "Filesys::POSIX->stat('/..') returns the root vnode"
    );

    my $fd = $fs->open( 'foo', $O_CREAT | $O_WRONLY );
    my $inode = $fs->fstat($fd);

    throws_errno_ok {
        $fs->fchdir($fd);
    }
    &Errno::ENOTDIR, "Filesys::POSIX->fchdir() fails on non-directory file descriptor";

    $fs->close($fd);

    throws_errno_ok {
        $fs->stat('foo/bar');
    }
    &Errno::ENOTDIR, "Filesys::POSIX->stat() will not walk a path with non-directory parent components";

    throws_errno_ok {
        $fs->open( 'foo/bar', $O_CREAT | $O_WRONLY );
    }
    &Errno::ENOTDIR, "Filesys::POSIX->open() prevents attaching children to non-directory inodes";

    throws_errno_ok {
        $fs->link( 'foo', '/mnt/bar' );
    }
    &Errno::EXDEV, "Filesys::POSIX->link() prevents cross-device links";

    $fs->link( 'foo', 'bar' );
    ok(
        $inode eq $fs->stat('bar'),
        "Filesys::POSIX->link() copies inode reference into directory entry"
    );

    lives_ok {
        $fs->link( 'bar', 'eins' );
        $fs->rename( 'eins', 'bar' );
    }
    "Filesys::POSIX->rename() can replace non-directory entries with other non-directory entries";

    throws_errno_ok {
        $fs->link( 'foo', 'bar' );
    }
    &Errno::EEXIST, "Filesys::POSIX->link() dies when destination already exists";

    $fs->rename( 'bar', 'baz' );
    ok(
        $inode eq $fs->stat('baz'),
        "Filesys::POSIX->rename() does not modify inode reference in directory entry"
    );

    throws_errno_ok {
        $fs->rename( 'baz', '/mnt/boo' );
    }
    &Errno::EXDEV, "Filesys::POSIX->rename() dies whe renaming inodes across different devices";

    $fs->unlink('baz');

    throws_errno_ok {
        $fs->stat('baz');
    }
    &Errno::ENOENT, "Filesys::POSIX->unlink() removes reference to inode from directory entry";

    throws_errno_ok {
        $fs->unlink('baz');
    }
    &Errno::ENOENT, "Filesys::POSIX->unlink() dies when its target does not exist";

    ok(
        $inode eq $fs->stat('foo'),
        "Filesys::POSIX->unlink() does not actually destroy inode"
    );

    throws_errno_ok {
        $fs->rmdir('foo');
    }
    &Errno::ENOTDIR, "Filesys::POSIX->rmdir() prevents removal of non-directory inodes";

    throws_errno_ok {
        $fs->rmdir('cats');
    }
    &Errno::ENOENT, "Filesys::POSIX->rmdir() dies when target does not exist in its parent";

    throws_errno_ok {
        $fs->rmdir('/mnt');
    }
    &Errno::EBUSY, "Filesys::POSIX->rmdir() dies when removing a mount point";
}

{
    my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );
    $fs->mkdir('meow');

    my $inode = $fs->stat('meow');

    ok(
        $inode->dir,
        "Filesys::POSIX->mkdir() creates directory inodes in the expected manner"
    );

    throws_errno_ok {
        $fs->unlink('meow');
    }
    &Errno::EISDIR, "Filesys::POSIX->unlink() prevents removal of directory inodes";

    throws_errno_ok {
        $fs->link( 'meow', 'cats' );
    }
    &Errno::EISDIR, "Filesys::POSIX->link() prevents linking of directory inodes";

    throws_errno_ok {
        $fs->rmdir('meow');
        $fs->stat('meow');
    }
    &Errno::ENOENT, "Filesys::POSIX->rmdir() actually functions";

    throws_errno_ok {
        $fs->mkdir('meow');
        $fs->touch('meow/poo');
        $fs->rmdir('meow');
    }
    &Errno::ENOTEMPTY, "Filesys::POSIX->rmdir() prevents removing populated directories";

    throws_errno_ok {
        $fs->chdir('meow/poo');
    }
    &Errno::ENOTDIR, "Filesys::POSIX->chdir() fails on non directory inodes";

    throws_errno_ok {
        $fs->mkdir('cats');
        $fs->rename( 'cats', 'meow' );
    }
    &Errno::ENOTEMPTY, "Filesys::POSIX->rename() fails when replacing a non-empty directory";

    lives_ok {
        $fs->unlink('meow/poo');
        $fs->rename( 'cats', 'meow' );
    }
    "Filesys::POSIX->rename() can replace empty directories with other empty directories";

    $fs->touch('foo');

    throws_errno_ok {
        $fs->open( 'foo', $O_CREAT | $O_WRONLY | $O_EXCL );
    }
    &Errno::EEXIST, "Filesys::POSIX->open() prevents clobbering existing inodes with \$O_CREAT | \$O_EXCL";

    throws_errno_ok {
        $fs->rename( 'meow', 'foo' );
    }
    &Errno::ENOTDIR, "Filesys::POSIX->rename() prevents replacing directories with non-directories";

    throws_errno_ok {
        $fs->rename( 'foo', 'meow' );
    }
    &Errno::EISDIR, "Filesys::POSIX->rename() prevents replacing non-directories with directories";
}

{
    my $fs    = Filesys::POSIX->new( Filesys::POSIX::Mem->new );
    my $fd    = $fs->open( 'foo', $O_CREAT | $O_WRONLY, 0644 );
    my $inode = $fs->fstat($fd);
    $fs->close($fd);

    $fs->mkpath('eins/zwei/drei');
    $fs->symlink( 'zwei', 'eins/foo' );

    ok(
        $fs->stat('eins/zwei/drei') eq $fs->lstat('eins/foo/drei'),
        "Filesys::POSIX->lstat() resolves symlinks in tree"
    );

    throws_errno_ok {
        $fs->readlink('foo');
    }
    &Errno::EINVAL, "Filesys::POSIX->readlink() fails on non-symlink inodes";

    $fs->symlink( 'foo', 'bar' );
    my $link = $fs->lstat('bar');

    ok(
        $inode eq $fs->stat('bar'),
        "Filesys::POSIX->stat() works on symlinks"
    );
    ok(
        $fs->readlink('bar') eq 'foo',
        "Filesys::POSIX->readlink() returns expected result"
    );
}

{
    my $fs    = Filesys::POSIX->new( Filesys::POSIX::Mem->new );
    my $fd    = $fs->open( '/foo', $O_CREAT, $S_IFDIR | 0755 );
    my $inode = $fs->fstat($fd);

    $fs->fchdir($fd);
    ok(
        $fs->getcwd eq '/foo',
        "Filesys::POSIX->fchdir() changes current directory when passed a directory fd"
    );

    $fs->fchown( $fd, 500, 500 );
    ok(
        $inode->{'uid'} == 500,
        "Filesys::POSIX->fchown() updates inode's uid properly"
    );
    ok(
        $inode->{'gid'} == 500,
        "Filesys::POSIX->fchown() updates inode's gid properly"
    );

    $fs->fchmod( $fd, 0700 );
    ok(
        ( $inode->{'mode'} & $S_IPERM ) == 0700,
        "Filesys::POSIX->fchmod() updates inode's permissions properly"
    );
}

{
    my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

    foreach my $dir (qw(dev tmp var)) {
        $fs->mkdir($dir);
    }

    {
        my $inode = $fs->mknod( '/dev/null', $S_IFCHR | 0666, ( 1 << 16 ) | 3 );

        ok(
            $inode->char,
            'Filesys::POSIX->mknod() creates character devices approrpiately'
        );
        is(
            $inode->major, 1,
            'Filesys::POSIX::Inode->major() returns correct value on char devices'
        );
        is(
            $inode->minor, 3,
            'Filesys::POSIX::Inode->minor() returns correct value on char devices'
        );
    }

    {
        my $inode = $fs->mknod( '/dev/mem', $S_IFBLK | 0644, ( 1 << 16 ) | 1 );

        ok(
            $inode->block,
            'Filesys::POSIX->mknod() creates block devices appropriately'
        );
        is(
            $inode->major, 1,
            'Filesys::POSIX::Inode->major() returns correct value on block devices'
        );
        is(
            $inode->minor, 1,
            'Filesys::POSIX::Inode->minor() returns correct value on block devices'
        );
    }

    {
        my $inode = $fs->mknod( '/tmp/foo', $S_IFREG | 0644, ( 1 << 16 ) | 4 );

        throws_errno_ok {
            $inode->major;
        }
        &Errno::EINVAL, 'Filesys::POSIX::Inode->major() dies on non-char, non-block inodes';

        throws_errno_ok {
            $inode->minor;
        }
        &Errno::EINVAL, 'Filesys::POSIX::Inode->minor() dies on non-char, non-block inodes';
    }

    {
        my $inode = $fs->mkfifo( '/var/test', 0644 );

        ok(
            $inode->fifo,
            'Filesys::POSIX::Inode->fifo() returns true on FIFO inodes'
        );
    }

    throws_errno_ok {
        $fs->mknod( '/foo/bar/baz', $S_IFREG | 0644 );
    }
    &Errno::ENOENT, 'Filesys::POSIX->mknod() dies when creating node in nonexistent directory';

    throws_errno_ok {
        $fs->mknod( '/dev/null', $S_IFREG | 0666, ( 1 << 16 ) | 3 );
    }
    &Errno::EEXIST, 'Filesys::POSIX->mknod() dies when a named inode already exists';

    throws_errno_ok {
        $fs->mknod( '/tmp/bar', 0644 );
    }
    &Errno::EINVAL, 'Filesys::POSIX->mknod() throws Invalid Argument when no inode format specified';

    lives_ok {
        $fs->mkdir('/test');
        $fs->mkdir('/test/foo');
        $fs->rename( '/test', '/test2' );
    }
    'Filesys::POSIX->rename() succeeds when renaming a non-empty directory';

    lives_ok {
        $fs->mkdir('/shouldnotfail');
        $fs->mkdir('/shouldnotfail/0');
    }
    'Filesys::POSIX->mkdir() does not fail when creating a new subdirectory named "0"';
}
