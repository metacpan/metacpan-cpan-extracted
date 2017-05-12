# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# TODO: test the bind call, with and without existence

use strict;

use Test::More tests => 5;

use Fcntl qw( :flock );
use IPC::Shm::Simple;

use vars qw( $KEY $pid $val );

# If a semaphore or shared memory segment already uses this
# key, the first set of tests will fail, and the script will die()
$KEY = 192; 

my ( $share );

# Test object rebind
ok( $share = IPC::Shm::Simple->bind($KEY), 'bind key=192' );

# continue testing only if we actually have a segment
die $! unless $share;

# Get a lock
ok( $share->readlock, '... get a shared lock\n' );

# Retrieve value
is( $share->fetch, '7836', '... fetch and compare' );

# mark share for deletion
ok( $share->remove(), 'remove segment from the system' );

# cause undefine - test returns true to prove the script is still running
undef $share;
ok( 1, '... undefine to trigger destructor' );

