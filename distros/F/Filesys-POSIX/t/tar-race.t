# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;
use autodie;

use Test::More ( 'tests' => 9 );
use File::Temp ();

use lib "lib";
use ExtUtils::testlib;

use Filesys::POSIX                ();
use Filesys::POSIX::Mem           ();
use Filesys::POSIX::Real          ();
use Filesys::POSIX::IO::Handle    ();
use Filesys::POSIX::Userland::Tar ();
use Filesys::POSIX::Extensions    ();

my $t = time();

my $child;

# These tests serve to exercise the fixes made in cases 90017 and 92573.

# Each test has a writer and a checker. The writer is passed the temporary directory
# as an argument, and it must write one or more files under $temp_dir/orig_dir. The
# reader is also passed the temporary directory, and it must extract the tarball
# called 'test.tar' and verify that the extracted contents under $temp_dir/mapped_dir
# match what was expected. The file should always be called file.txt.
my @tests = (
    {
        writer => sub {
            my $temp_dir = shift;
            _write_file( "$temp_dir/orig_dir/file.txt", "$t\n" );
        },
        checker => sub {
            my $temp_dir = shift;
            chdir $temp_dir;
            note `tar xvpf test.tar 2>&1`;
            ok !$?, "Archive was extracted successfully (normal)";
            is _read_file("$temp_dir/mapped_dir/file.txt"), "$t\n", "Basic archiving works";
        },
    },
    {
        writer => sub {
            my $temp_dir = shift;

            if ( $child = fork ) {
                select undef, undef, undef, 0.4;
            }
            elsif ( defined $child ) {
                _write_file( "$temp_dir/orig_dir/file.txt", '' );
                open my $fh, '+<', "$temp_dir/orig_dir/file.txt";
                for ( my $len = 5e7; $len >= 0; $len-- ) {
                    truncate $fh, $len;
                }
                close $fh;
                exit;
            }
            else { die "fork: $!"; }
        },
        checker => sub {
            my ( $temp_dir, $warnings ) = @_;

            my ( $expect_total, $got_total ) = ( $warnings->[0] || '' ) =~ /WARNING: Short read while archiving file \(expected total of (\d+) bytes, but only got (\d+)\); padding with null bytes\.\.\./;
            chdir $temp_dir;
            note `tar xvpf test.tar 2>&1`;
            ok !$?, "Archive was extracted successfully (truncate)";
            my $size = ( stat "$temp_dir/mapped_dir/file.txt" )[7];
            cmp_ok $size, '<', 5e7, "Archived file is smaller than initial size";
            cmp_ok $size, '>', 0,   "Archived file has at least some content";
          SKIP: {
                skip "oops: didn't get a warning", 1 if !defined($expect_total);
                is $size, $expect_total, "The actual file size we got matches the size the warning claimed to have expected, so the file was padded";    # check that the file in the archive was padded to match the expected size

            }
            kill 'KILL', $child;
            waitpid $child, 0;
        },
    },
    {
        writer => sub {
            my $temp_dir = shift;

            if ( $child = fork ) {
                select undef, undef, undef, 0.4;
            }
            elsif ( defined $child ) {
                _write_file( "$temp_dir/orig_dir/file.txt", '' );
                open my $fh, '+<', "$temp_dir/orig_dir/file.txt";
                for ( my $len = 1; $len <= 5e7; $len++ ) {
                    truncate $fh, $len;
                }
                close $fh;
                exit;
            }
            else { die "fork: $!"; }
        },
        checker => sub {
            my ( $temp_dir, $warnings ) = @_;

            chdir $temp_dir;
            note `tar xvpf test.tar 2>&1`;
            ok !$?, "Archive was extracted successfully (append)";
            my $size = ( stat "$temp_dir/mapped_dir/file.txt" )[7];
            cmp_ok $size, '>', 0,   "Archived file has at least some content";
            cmp_ok $size, '<', 5e7, "Archived file did not grow to maximum size";
            kill 'KILL', $child;
            waitpid $child, 0;
        },
    },
);

for my $t (@tests) {
    execute_single_test($t);
}

# allow temp dir cleanup to happen
chdir '/';

exit;

##############################################################################

sub execute_single_test {
    my $args = shift;

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $orig_dir = "$dir/orig_dir";
    mkdir $orig_dir;

    $args->{writer}->($dir) if ref $args->{writer} eq 'CODE';

    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, shift;
    };

    my $fs = Filesys::POSIX->new( Filesys::POSIX::Real->new, path => $orig_dir );
    $fs->map( $orig_dir, "/mapped_dir" );

    open my $tar_fh, ">", "$dir/test.tar";
    my $handle = Filesys::POSIX::IO::Handle->new($tar_fh);
    $fs->tar( $handle, "/mapped_dir/file.txt" );
    $handle->close;

    $args->{checker}->( $dir, \@warnings ) if ref $args->{checker} eq 'CODE';
}

sub _read_file {
    my $file = shift;
    open my $fh, '<', $file;
    local $/;
    return readline $fh;
}

sub _write_file {
    my ( $file, $contents ) = @_;
    open my $fh, '>', $file;
    print {$fh} $contents;
    close $fh;
}
