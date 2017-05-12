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
use Filesys::POSIX::Userland::Test ();
use Filesys::POSIX::Bits;

use Test::More ( 'tests' => 80 );

my $fs = Filesys::POSIX->new( Filesys::POSIX::Mem->new, 'noatime' => 1 );

sub controlled_test {
    my ( $expected, $tests, $controls, @exclude ) = @_;

    foreach my $test_name ( sort keys %{$tests} ) {
        my $test = $tests->{$test_name};

        foreach my $control_name ( sort keys %{$controls} ) {
            next if $control_name eq $test_name;
            next if grep { $_ eq $control_name } @exclude;

            my $control = $controls->{$control_name};

            my $file = $control->{'file'};
            my $type = $control->{'type'};

            my $result = $test->{'test'}->($file);
            my $condition = $expected ? 'true' : 'false';

            ok(
                $expected == $result,
                "\$fs->$test_name() returns $condition when given a $type inode ($file)"
            );
        }
    }
}

my %EXISTENCE_TESTS = (
    'exists' => {
        'init' => sub { $fs->touch(shift) },
        'test' => sub { $fs->exists(shift) },
        'file' => '/tmp/test',
        'type' => 'regular file'
    }
);

my %FORMAT_TESTS = (
    'is_file' => {
        'init' => sub { $fs->touch(shift) },
        'test' => sub { $fs->is_file(shift) },
        'file' => '/tmp/file',
        'type' => 'regular file'
    },

    'is_dir' => {
        'init' => sub { $fs->mkdir(shift) },
        'test' => sub { $fs->is_dir(shift) },
        'file' => '/tmp/dir',
        'type' => 'directory'
    },

    'is_link' => {
        'init' => sub { $fs->symlink( 'file', shift ) },
        'test' => sub { $fs->is_link(shift) },
        'file' => '/tmp/link',
        'type' => 'symbolic link'
    },

    'is_char' => {
        'init' => sub { $fs->mknod( shift, $S_IFCHR | 0644, 0x0103 ) },
        'test' => sub { $fs->is_char(shift) },
        'file' => '/dev/null',
        'type' => 'character device'
    },

    'is_block' => {
        'init' => sub { $fs->mknod( shift, $S_IFBLK | 0644, 0x0800 ) },
        'test' => sub { $fs->is_block(shift) },
        'file' => '/dev/sda',
        'type' => 'block device'
    },

    'is_fifo' => {
        'init' => sub { $fs->mkfifo( shift, 0644 ) },
        'test' => sub { $fs->is_fifo(shift) },
        'file' => '/tmp/fifo',
        'type' => 'FIFO buffer'
    }
);

my %PERM_TESTS = (
    'is_readable' => {
        'init' => sub {
            my $fd = $fs->open( shift, $O_CREAT, 0400 );
            $fs->close($fd);
        },

        'test' => sub { $fs->is_readable(shift) },
        'file' => '/tmp/readable',
        'type' => 'readable file (0400)'
    },

    'is_writable' => {
        'init' => sub {
            my $fd = $fs->open( shift, $O_CREAT, 0200 );
            $fs->close($fd);
        },

        'test' => sub { $fs->is_writable(shift) },
        'file' => '/tmp/writable',
        'type' => 'writable file (0200)'
    },

    'is_executable' => {
        'init' => sub {
            my $fd = $fs->open( shift, $O_CREAT, 0100 );
            $fs->close($fd);
        },

        'test' => sub { $fs->is_executable(shift) },
        'file' => '/bin/sh',
        'type' => 'executable file (0100)'
    },

    'is_setuid' => {
        'init' => sub {
            my $fd = $fs->open( shift, $O_CREAT, $S_ISUID );
            $fs->close($fd);
        },

        'test' => sub { $fs->is_setuid(shift) },
        'file' => '/tmp/setuid',
        'type' => 'setuid file (04000)'
    },

    'is_setgid' => {
        'init' => sub {
            my $fd = $fs->open( shift, $O_CREAT, $S_ISGID );
            $fs->close($fd);
        },

        'test' => sub { $fs->is_setgid(shift) },
        'file' => '/tmp/setgid',
        'type' => 'setgid file (02000)'
    }
);

my %ALL_TESTS = ( %EXISTENCE_TESTS, %FORMAT_TESTS, %PERM_TESTS );

$fs->mkdir('/bin');
$fs->mkdir('/dev');
$fs->mkdir('/tmp');

#
# First, perform a run of every test to ensure the happy path works
#
foreach my $name ( sort keys %ALL_TESTS ) {
    my $test = $ALL_TESTS{$name};
    my $file = $test->{'file'};
    my $type = $test->{'type'};

    $test->{'init'}->($file);

    my $result = $test->{'test'}->($file);

    ok(
        $result,
        "\$fs->$name() returns true when passed a $type inode ($file)"
    );
}

#
# Perform the existence tests against all test data
#
controlled_test( 1, \%EXISTENCE_TESTS, \%ALL_TESTS );

#
# Perform the mutually exclusive format tests against one another.
#
controlled_test( 0, \%FORMAT_TESTS, \%FORMAT_TESTS, 'is_link' );

#
# Perform the mutually exclusive permissions tests against one another.
#
controlled_test( 0, \%PERM_TESTS, \%PERM_TESTS );

#
# Perform all the tests against a nonexistent file.
#
controlled_test(
    0,
    \%ALL_TESTS,
    {
        'nonexistent' => {
            'file' => '/tmp/nonexistent',
            'type' => 'nonexistent file'
        }
    }
);
