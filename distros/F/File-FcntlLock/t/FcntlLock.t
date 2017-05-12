# -*- cperl -*-
#
#  This program is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  Copyright (C) 2002-2014 Jens Thoms Toerring <jt@toerring.de>
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FcntlLock.t'


#########################

use strict;
use warnings;
use Test;
use POSIX;
use File::FcntlLock::Core;

my @modules;

BEGIN {
    my $num_tests = 8;

    # Check which packages are usable and only test those

    for ( qw/ File::FcntlLock::XS
              File::FcntlLock::Pure
              File::FcntlLock::Inline / ) {
        eval "use $_";
        unless ( $@ ) {
            push @modules, $_;
            $num_tests += 3;
        }
    }

    die "Can't use any of the packages\n" unless $num_tests > 8;

    plan tests => $num_tests;
}


##############################################
# 1. Most basic test: create an object

my $fs = new File::FcntlLock::Core;
ok( defined $fs and $fs->isa( 'File::FcntlLock::Core' ) );


##############################################
# 2. Also basic: create an object with initalization and check thet the
#    properties of the created object are what they are supposed to be

$fs = new File::FcntlLock::Core l_type   => F_RDLCK,
                                l_whence => SEEK_CUR,
                                l_start  => 123,
                                l_len    => 234;
ok(     defined $fs
    and $fs->isa( 'File::FcntlLock::Core' )
    and $fs->l_type   == F_RDLCK 
    and $fs->l_whence == SEEK_CUR
    and $fs->l_start  == 123
    and $fs->l_len    == 234      );


##############################################
# 3. Change l_type property to F_UNLCK and check

$fs->l_type( F_UNLCK );
ok( $fs->l_type, F_UNLCK );


##############################################
# 4. Change l_type property to F_WRLCK and check

$fs->l_type( F_WRLCK );
ok( $fs->l_type, F_WRLCK );


##############################################
# 5. Change l_whence property to SEEK_END and check

$fs->l_whence( SEEK_END );
ok( $fs->l_whence, SEEK_END );


##############################################
# 6. Change l_whence property to SEEK_SET and check

$fs->l_whence( SEEK_SET );
ok( $fs->l_whence, SEEK_SET );


##############################################
# 7. Change l_start property and check

$fs->l_start( 20 );
ok( $fs->l_start, 20 );


##############################################
# 8. Change l_len property and check

$fs->l_len( 3 );
ok( $fs->l_len, 3 );


##############################################
# 9.-17. Test for obtaining a read and write lock and then concurrent
#        locking of all three packages (or as far as the packages could
#        be loaded)

for my $module ( @modules ) {

    ##############################################
    # Test if we can get a read lock on a file and release it again

    ok( test_read_lock( $module ) );


    ##############################################
    # Test if we can get an write lock on a test file and release it again

    ok( test_write_lock( $module ) );


    ##############################################
    # Now a "real" test: the child process grabs a write lock on a test
    # file for 2 secs while the parent repeatedly tests if it can get the
    # lock. After the child finally releases the lock the parent should be
    # able to obtain and again release it. Note that there are systems
    # that don't support F_GETLK and in that case we can only try to
    # obtain the lock directly and check for the reason it failed.

    ok( test_concurrent_locking( $module ) );
}


##############################################
# Function run for tests 9, 12 and 15: tests if we can get a read lock
# on a file and release it again

sub test_read_lock {
    my $module = shift;

    my $fh;
    unless ( defined open $fh, '>', './fcntllock_test' ) {
        print "# Can't create a test file: $!\n";
        return 0;
    }
    close $fh;

    unless ( defined open $fh, '<', './fcntllock_test' ) {
        print "# Can't open a file for reading: $!\n";
        unlink './fcntllock_test';
        return 0;
    }
    unlink './fcntllock_test';

    my $fs = $module->new( );

    $fs->l_type( F_RDLCK );
    $fs->l_start( 0 );                    # that's all GNU Hurd can handle
    $fs->l_len( 0 );                      # ditto
    $fs->l_whence( SEEK_SET );            # ditto
    my $res = $fs->lock( $fh, F_SETLK );

    if ( defined $res ) {
        $fs->l_type( F_UNLCK );
        $res = $fs->lock( $fh, F_SETLK );
        print "# Dropping read lock failed: $! (" . $fs->lock_errno . ")\n"
            unless defined $res;
    } else {
        print "# Read lock failed: $! (" . $fs->lock_errno . ")\n";
    }

    close $fh;
    return defined $res;
}


##############################################
# Function run fot test 10, 13 and 16: tests if we can get an write lock
# on a test file and release it again

sub test_write_lock {
    my $module = shift;

    my $fh;
    unless ( defined open $fh, '>', './fcntllock_test' ) {
        print "# Can't open a file for writing: $!\n";
        return 0;
    }
    unlink './fcntllock_test';

    my $fs = $module->new( );

    $fs->l_type( F_WRLCK );
    my $res = $fs->lock( $fh, F_SETLK );

    if ( defined $res ) {
        $fs->l_type( F_UNLCK );
        $res = $fs->lock( $fh, F_SETLK );
        print   "# Dropping write lock failed: $! (" . $fs->lock_errno . ")\n"
            unless defined $res;
    } else {
        print "# Write lock failed: $! (" . $fs->lock_errno . ")\n";
    }

    close $fh;
    return defined $res;
}


##############################################
# Function run for test 11, 14 and 17: the child process grabs a write lock
# on a test file for 2 secs while the parent repeatedly tests if it can get
# the lock. After the child finally releases the lock the parent should be
# able to obtain and again release it. Note that there are systems that do
# not support F_GETLK and in that case we can only try to obtain the lock
# directly and check for the reason it failed.

sub test_concurrent_locking {
    my $module = shift;

    my $fh;
    unless ( defined open $fh, '>', './fcntllock_test' ) {
        print "# Can't open a file for writing: $!\n";
        return 0;
    }
    unlink './fcntllock_test';

    my $fs = $module->new( l_type   => F_WRLCK,
                           l_whence => SEEK_SET,
                           l_start  => 0,
                           l_len    => 0 );

    my $res = 0;

    if ( my $pid = fork ) {
        sleep 1;             # leave some time for the child to get the lock
        my $failed = 1;

        while ( 1 ) {
            # Check for abnormal exit of the child process

            last if $pid == waitpid( $pid, WNOHANG ) and $?;

            # F_GETLK is not supported on all systems in which case errno
            # is set to ENOSYS. In that case we have to resort to trying to
            # obtain the lock directly and testing the reasons for failure,
            # not being able to obtain information about the holder of the
            # lock.

            if ( ! defined $fs->lock( $fh, F_GETLK ) ) {
                last unless $!{ ENOSYS };
                $fs->l_type( F_WRLCK );
                if ( ! defined $fs->lock( $fh, F_SETLK ) ) {
                    last unless $!{ EACCES } or ! $!{ EAGAIN };
                } else {
                    $fs->l_type( F_UNLCK );
                    last unless defined $fs->lock( $fh, F_SETLK );
                    $failed = 0;
                    last;
                }
            } else {
                last if $fs->l_type == F_WRLCK and $fs->l_pid != $pid;
                if ( $fs->l_type == F_UNLCK ) {
                    $failed = 0;
                    last;
                }
            }
            select undef, undef, undef, 0.25;
        }

        if ( ! $failed ) {
            $res =     $fs->l_type( F_WRLCK ), $fs->lock( $fh, F_SETLK )
                   and $fs->l_type( F_UNLCK ), $fs->lock( $fh, F_SETLK );
        }
    } elsif ( defined $pid ) {                     # child's code
        $fs->lock( $fh, F_SETLKW ) or exit 1;
        sleep 2;
        $fs->l_type( F_UNLCK ) or exit 1;
        $fs->lock( $fh, F_SETLK ) or exit 1;
        exit 0;
    } else {
        print "# Can't fork: $!\n";
    }

    close $fh;
    return $res;
}


# Local variables:
# tab-width: 4
# indent-tabs-mode: nil
# End:
