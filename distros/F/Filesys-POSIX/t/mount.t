# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX       ();
use Filesys::POSIX::Mem  ();
use Filesys::POSIX::Real ();
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 32 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

my $mounts = {
    '/'            => Filesys::POSIX::Mem->new,
    '/mnt/mem'     => Filesys::POSIX::Mem->new,
    '/mnt/mem/tmp' => Filesys::POSIX::Mem->new
};

my $fs = Filesys::POSIX->new( $mounts->{'/'} );

$fs->mkpath('/mnt/mem/hidden');

foreach ( grep { $_ ne '/' } sort keys %$mounts ) {
    lives_ok {
        $fs->mkpath($_);
    }
    "Able to create mount point $_";

    lives_ok {
        $fs->mount( $mounts->{$_}, $_, 'noatime' => 1 );
    }
    "Able to mount $mounts->{$_} to $_";

    throws_errno_ok {
        $fs->mount( $mounts->{$_}, $_, 'noatime' => 1 );
    }
    &Errno::EBUSY, "Filesys::POSIX->mount() complains when requested device is already mounted";
}

throws_errno_ok {
    $fs->stat('/mnt/mem/hidden');
}
&Errno::ENOENT, "Mounting /mnt/mem sweeps /mnt/mem/hidden under the rug";

{
    my $expected = $mounts->{'/'};
    my $result   = $fs->{'root'}->{'dev'};

    ok( $result eq $expected, "Filesystem root device lists $result" );
}

foreach ( sort keys %$mounts ) {
    my $inode = $fs->stat($_);

    my $expected = $mounts->{$_};
    my $result   = $inode->{'dev'};

    ok( $result eq $expected, "$_ inode lists $result as device" );

    my $mount = eval { $fs->statfs($_); };

    my $fd = $fs->open( "$_/emptyfile", $O_CREAT );

    ok( !$@, "Filesys::POSIX->statfs('$_/') returns mount information" );
    ok(
        $mount->{'dev'} eq $expected,
        "Mount object for $_ lists expected device"
    );
    ok(
        $fs->fstatfs($fd) eq $mount,
        "Filesys::POSIX->fstatfs() on open file descriptor returns expected mount object"
    );

    $fs->close($fd);
}

{
    my $found = 0;

    foreach my $mount ( $fs->mountlist ) {
        $found++ if $mounts->{ $mount->{'path'} };
    }

    ok(
        $found == keys %$mounts,
        "Filesys::POSIX->mountlist() works expectedly"
    );
}

{
    $fs->chdir('/mnt/mem/tmp');
    ok(
        $fs->getcwd eq '/mnt/mem/tmp',
        "Filesys::POSIX->getcwd() reports /mnt/mem/tmp after a chdir()"
    );

    $fs->chdir('..');
    ok(
        $fs->getcwd eq '/mnt/mem',
        "Filesys::POSIX->getcwd() reports /mnt/mem after a chdir('..')"
    );

    $fs->chdir('..');
    ok(
        $fs->getcwd eq '/mnt',
        "Filesys::POSIX->getcwd() reports /mnt after a chdir('..')"
    );

    $fs->chdir('..');
    ok(
        $fs->getcwd eq '/',
        "Filesys::POSIX->getcwd() reports / after a chdir('..')"
    );
}

{
    my $fd = $fs->open( '/mnt/mem/test.txt', $O_CREAT );

    throws_errno_ok {
        $fs->unmount('/mnt/mem');
    }
    &Errno::EBUSY, "Filesys::POSIX->unmount() prevents unmounting busy filesystem /mnt/mem";

    $fs->close($fd);
    $fd = $fs->open( '/foo.txt', $O_CREAT );

    throws_errno_ok {
        $fs->unmount('/mnt/mem');
    }
    &Errno::EBUSY, "Filesys::POSIX->unmount() prevents unmounting busy filesystem /mnt/mem";

    throws_errno_ok {
        $fs->chdir('/mnt/mem');
        $fs->unmount('/mnt/mem');
    }
    &Errno::EBUSY, "Filesys::POSIX->unmount() fails when cwd is /mnt/mem";

    $fs->chdir('/');

    $fs->close($fd);
}

{
    $fs->mkdir("real");
    $fs->mkdir("real/0");
    my $inode = eval { $fs->stat('real/0') };
    ok($inode, 'Mkdir of real/0 succeeded');
    diag($@) if $@;

    $fs->mount( Filesys::POSIX::Real->new, 'real/0', path => '/' );
    $inode = eval { $fs->stat('real/0/etc/passwd') };
    ok( $inode, 'Mount at real/0 functions properly' );
    diag($@) if $@;
    $fs->unmount('real/0');
}

{
    $fs->unmount('/mnt/mem/tmp');
    $fs->unmount('/mnt/mem');

    throws_errno_ok {
        $fs->stat('/mnt/mem/tmp');
    }
    &Errno::ENOENT, "/mnt/mem/tmp can no longer be accessed after unmounting /mnt/mem";
}
