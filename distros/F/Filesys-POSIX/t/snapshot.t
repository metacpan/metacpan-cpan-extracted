# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::Bits;

use Filesys::POSIX           ();
use Filesys::POSIX::Mem      ();
use Filesys::POSIX::Snapshot ();

use Test::More ( 'tests' => 10 );
use Test::Exception;
use Test::Filesys::POSIX::Error;

sub mkskelfs {
    my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

    my @DIRS = qw(
      bin dev etc etc/init.d home lib mnt mnt/cdrom root tmp usr var
    );

    my %DEVICES = (
        'null'    => [ $S_IFCHR, 0666, 1, 3 ],
        'random'  => [ $S_IFCHR, 0666, 1, 8 ],
        'urandom' => [ $S_IFCHR, 0666, 1, 9 ],
        'zero'    => [ $S_IFCHR, 0666, 1, 5 ],
        'sda'     => [ $S_IFBLK, 0664, 8, 0 ],
        'tty'     => [ $S_IFCHR, 0666, 5, 0 ],
        'tty0'    => [ $S_IFCHR, 0600, 4, 0 ],
        'tty1'    => [ $S_IFCHR, 0600, 4, 1 ],
        'tty2'    => [ $S_IFCHR, 0600, 4, 2 ],
        'tty3'    => [ $S_IFCHR, 0600, 4, 3 ],
    );

    my %FILES = (
        '/bin/sh'        => 0755,
        '/etc/init.d/rc' => 0755
    );

    foreach my $dir (@DIRS) {
        $fs->mkdir($dir);
    }

    foreach my $file ( keys %FILES ) {
        my $mode = $FILES{$file};

        my $fd = $fs->open( $file, $O_CREAT | $O_WRONLY, $mode );
        $fs->fchmod( $fd, $mode );
        $fs->close($fd);
    }

    $fs->symlink( 'sh', '/bin/ksh' );

    my $fd = $fs->open( '/etc/hosts', $O_CREAT | $O_WRONLY );
    $fs->print( $fd, "127.0.0.1 localhost\n" );
    $fs->print( $fd, "::1 ip6-localhost ip6-loopback\n" );
    $fs->close($fd);

    foreach my $device ( keys %DEVICES ) {
        my ( $type, $mode, $major, $minor ) = @{ $DEVICES{$device} };

        $fs->mknod( "/dev/$device", $type | $mode, ( $major << 16 ) | $minor );
    }

    return $fs;
}

{
    my $fs = mkskelfs();

    throws_errno_ok {
        $fs->mkpath('/snapshots/1');

        $fs->mount( Filesys::POSIX::Snapshot->new, '/snapshots/1' );
    }
    &Errno::EINVAL, "Filesys::POSIX::Snapshot->new() emits 'Invalid argument' when no 'path' is specified";

    lives_ok {
        $fs->mkpath('/snapshots/2');

        $fs->mount(
            Filesys::POSIX::Snapshot->new,
            '/snapshots/2', 'path' => '/'
        );
    }
    "Filesys::POSIX::Snapshot->new() succeeds when 'path' is specified";

    throws_errno_ok {
        $fs->mkpath('/snapshots/3');

        $fs->mount(
            Filesys::POSIX::Snapshot->new,
            '/snapshots/3', 'path' => '/dev/null'
        );
    }
    &Errno::ENOTDIR, "Filesys::POSIX::Snapshot->new() emits 'Not a directory' when non-directory 'path' specified";
}

{
    my $fs = mkskelfs();

    lives_ok {
        $fs->mkpath('/snapshots/1');

        $fs->mount(
            Filesys::POSIX::Snapshot->new, '/snapshots/1',
            'path'               => '/',
            'immediate_dir_copy' => 1
        );
    }
    "Filesys::POSIX::Snapshot::Inode->new() lives when FS mounted with 'immediate_dir_copy'";

    isa_ok(
        $fs->stat('/snapshots/1/dev')->{'directory'},
        "Filesys::POSIX::Mem::Directory",
        '/snapshots/1/dev'
    );
    is(
        $fs->lstat('/snapshots/1/bin/ksh')->readlink,
        'sh', "Symlinks are copied by Filesys::POSIX::Snapshot"
    );

    #
    # Prepare for testing copy-on-write functionality in extent.
    #
    note('Preparing to test regular file copy-on-write; using /foo');

    $fs->touch('/file');
    $fs->mkdir('/dir');

    $fs->mkpath('/snapshots/2');
    $fs->mount( Filesys::POSIX::Snapshot->new, '/snapshots/2', 'path' => '/' );

    note('Mounted snapshot of / in /snapshots/2');

    my $fd = $fs->open( '/snapshots/2/file', $O_WRONLY | $O_APPEND );
    $fs->print( $fd, "foo\n" );
    $fs->close($fd);

    note('Appended "foo" to /snapshots/2/file');

    $fd = $fs->open( '/snapshots/2/file', $O_WRONLY | $O_APPEND );
    $fs->print( $fd, "bar\n" );
    $fs->close($fd);

    $fd = $fs->open( '/snapshots/2/file', $O_RDONLY );

    note('Appended "bar" to /snapshots/2/file');

    my $len = $fs->read( $fd, my $buf, 8 );
    is( $len, 8,            'Read 8 bytes from /snapshots/2/file' );
    is( $buf, "foo\nbar\n", 'read() expected data from /snapshots/2/file' );

    $fs->close($fd);

    #
    # Test other inode derivative methods against the same /snapshots/2/file
    # inode.
    #
    my $inode = $fs->stat('/snapshots/2/file');

    throws_errno_ok {
        $inode->directory;
    }
    &Errno::ENOTDIR, 'Filesys::POSIX::Snapshot::Inode->directory() throws "Not a directory" as appropriate';

    #
    # Exercise code that avoids performing copy-on-write when performing readonly
    # open()s.
    #
    $fd = $fs->open( '/snapshots/2/etc/hosts', $O_RDONLY );

    ok(
        !defined $fs->fstat($fd)->{'bucket'},
        'Filesys::POSIX::Snapshot::Inode->open() avoids copy-on-write in RO mode'
    );

    $fs->close($fd);
}
