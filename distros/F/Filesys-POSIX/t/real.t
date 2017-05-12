# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX       ();
use Filesys::POSIX::Real ();
use Filesys::POSIX::Bits;
use Filesys::POSIX::Extensions ();

use File::Temp ();
use Fcntl;

use Test::More ( 'tests' => 19 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 );

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

my $fs = Filesys::POSIX->new( Filesys::POSIX::Real->new, 'path' => $tmpdir );

foreach ( sort keys %files ) {
    my $inode = $fs->stat($_);

    if ( $files{$_} eq 'file' ) {
        ok( $inode->file, "Filesys::POSIX::Real sees $_ as a file" );
        ok(
            $inode->{'size'} == 0,
            "Filesys::POSIX::Real sees $_ as a 0 byte file"
        );
    }
    elsif ( $files{$_} eq 'dir' ) {
        ok( $inode->dir, "Filesys::POSIX::Real sees $_ as a directory" );
    }
}

throws_errno_ok {
    Filesys::POSIX->new( Filesys::POSIX::Real->new );
}
&Errno::EINVAL, "Filesys::POSIX::Real->init() dies when no path is specified";

throws_errno_ok {
    Filesys::POSIX->new( Filesys::POSIX::Real->new, 'path' => '/dev/null' );
}
&Errno::ENOTDIR, "Filesys::POSIX::Real->init() dies when special is not a directory";

lives_ok {
    $fs->rename( 'foo', 'bleh' );
}
"Filesys::POSIX->rename() allows renaming real files";

$fs->alias( 'bar', 'baz' );

my $bar_inode = $fs->stat('bar');
my $baz_inode = $fs->stat('baz');

is_deeply( $bar_inode, $baz_inode, 'Aliased inode is the same physical path' );
ok( ( -e "$tmpdir/bar" ),  'Original real inode remains after aliasing' );
ok( ( !-e "$tmpdir/baz" ), 'New real inode was not created by aliasing' );

$fs->detach('bar');

ok( ( -e "$tmpdir/bar" ), 'Original real inode remains after detaching' );
dies_ok {
    $fs->stat('bar');
}
'Stat on detached path dies';

# list() was making detached names reappear previously
my @directory_contents = $fs->stat('.')->directory()->list();

ok((! grep { $_ eq 'bar' } @directory_contents), 'Detached name does not reappear from list() operation');

dies_ok {
    $fs->stat('bar');
}
'Stat on detached path dies after list()';

ok((grep { $_ eq 'baz' } @directory_contents), 'Aliased name remains after list() operation');
