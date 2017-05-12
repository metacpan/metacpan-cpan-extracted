# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX             ();
use Filesys::POSIX::Mem        ();
use Filesys::POSIX::Real       ();
use Filesys::POSIX::Extensions ();
use Filesys::POSIX::Directory  ();
use Filesys::POSIX::Bits;

use File::Temp ();

use Test::More ( 'tests' => 18 );
use Test::Exception;
use Test::NoWarnings;

my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 ) or die "$!";

my %mounts = (
    '/mnt/mem' => {
        'dev'   => Filesys::POSIX::Mem->new,
        'flags' => { 'noatime' => 1 }
    },

    '/mnt/real' => {
        'dev'   => Filesys::POSIX::Real->new,
        'flags' => {
            'path'    => $tmpdir,
            'noatime' => 1
        }
    }
);

my %files = (
    'foo'      => 'dir',
    'foo/bar'  => 'file',
    'foo/baz'  => 'dir',
    'foo/bleh' => 'file'
);

my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new );

foreach my $mountpoint ( sort keys %mounts ) {
    my $mount = $mounts{$mountpoint};

    $fs->mkpath($mountpoint);
    $fs->mount( $mount->{'dev'}, $mountpoint, %{ $mount->{'flags'} } );

    foreach ( sort keys %files ) {
        my $path = "$mountpoint/$_";

        if ( $files{$_} eq 'file' ) {
            $fs->touch($path);
        }
        elsif ( $files{$_} eq 'dir' ) {
            $fs->mkdir($path);
        }
    }

    my %members = (
        '.'    => 1,
        '..'   => 1,
        'bar'  => 1,
        'baz'  => 1,
        'bleh' => 1
    );

    {
        my $directory = $fs->opendir("$mountpoint/foo");
        my $type      = ref $directory;
        my $found     = 0;

        while ( my $member = $fs->readdir($directory) ) {
            $found++ if $members{$member};
        }

        $fs->closedir($directory);

        ok( $found == keys %members, "$type\->readdir() found each member" );
    }

    {
        my $directory = $fs->opendir("$mountpoint/foo");
        my $type      = ref $directory;
        my $found     = 0;

        foreach ( $fs->readdir($directory) ) {
            $found++ if $members{$_};
        }

        $fs->closedir($directory);

        ok(
            $found == keys %members,
            "$type\->readdir() returned each member in list context"
        );
    }

    {
        my $directory = $fs->stat("$mountpoint/foo")->directory;
        my $type      = ref $directory;
        my $found     = 0;

        foreach ( $directory->list ) {
            $found++ if $members{$_};
        }

        ok( $found == keys %members, "$type\->list() found each member" );
    }
}

#
# Test the Filesys::POSIX::Directory interface.  This is purely for the sake of
# code coverage.
#
{
    my $directory = bless {}, 'Filesys::POSIX::Directory';

    foreach (qw(get set exists detach delete list count open rewind read close)) {
        throws_ok {
            $directory->$_();
        }
        qr/^Not implemented/, "Filesys::POSIX::Directory->$_() throws 'Not implemented'";
    }
}
