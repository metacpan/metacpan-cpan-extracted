# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX                 ();
use Filesys::POSIX::Mem            ();
use Filesys::POSIX::Userland::Find ();
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 3 );
use Test::NoWarnings;

my %files = (
    '/foo'         => 'dir',
    '/foo/bar'     => 'dir',
    '/foo/bar/baz' => 'file',
    '/foo/boo'     => 'file',
    '/bleh'        => 'dir',
    '/bleh/cats'   => 'file',
    '/numeric',    => 'dir',
    map { '/numeric/' . $_ => 'file' } 0 .. 9
);

my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

foreach ( sort keys %files ) {
    if ( $files{$_} eq 'dir' ) {
        $fs->mkdir($_);
    }
    elsif ( $files{$_} eq 'file' ) {
        $fs->touch($_);
    }
}

$fs->symlink( '/bleh', '/foo/bar/meow' );

{
    my $found = 0;

    my %missing = %files;

    $fs->find(
        sub {
            my ( $path, $inode ) = @_;
            delete $missing{ $path->full };
        },
        '/'
    );

    is_deeply \%missing, {}, "no files or directories were missing from the find results"
      or note explain "Missing: ", \%missing;
}

{
    my %expected = (
        %files,
        '/foo/bar/meow'      => 1,
        '/foo/bar/meow/cats' => 1
    );

    my $found = 0;

    $fs->find(
        sub {
            my ( $path, $inode ) = @_;
            $found++ if $expected{ $path->full };
        },
        { 'follow' => 1 },
        '/'
    );

    ok(
        $found == keys %expected,
        "Filesys::POSIX->find() resolves and recurses into directory symlinks fine"
    );
}
