# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# TODO: test the bind call, with and without existence

use strict;

use Test::More tests => 31;

use Fcntl qw( :flock );
use IPC::Shm::Simple;

use vars qw( $KEY $pid $val );

# If a semaphore or shared memory segment already uses this
# key, the first set of tests will fail, and the script will die()
$KEY = 192; 

my ( $share );

# Test object construction
ok( $share = IPC::Shm::Simple->create($KEY, 256, 0660), 'create key=192' );

# continue testing only if we actually have a segment
die $! unless $share;

# check that the size took
is( $share->top_seg_size, 256, '... check its segment size' );

# check that the mode took
is( $share->flags, 0660, '... check its segment mode' );

# check that it is indeed blank
is( $share->length, 0, '... check zero data length' );
is( $share->serial, 1, '... check initial data serial' );

# detach from it
undef $share;
ok( 1, '... detach from it' );

# reattach to it
$share = IPC::Shm::Simple->attach($KEY);
ok( defined $share, '... reattach to it' );

# set its removal flag
ok( $share->remove(), 'remove it from the system' );

# actually remove it
undef $share;
ok( 1, '... undefine to trigger destructor' );

# try to reattach to it
$share = IPC::Shm::Simple->attach($KEY);
is( $share, undef, '... try to reattach, expect failure' );

# create a new anony
ok( $share = IPC::Shm::Simple->create(), 'create unkeyed shmseg' );

# continue testing only if we actually have a segment
die $! unless $share;

# Store value
ok( $share->store('maurice'), 'store short string value' );

# Retrieve value
is( $share->fetch, 'maurice', '... fetch and compare' );

# Fragmented store
ok( $share->store( "X" x 10000 ), 'store long (chunked) string value');

# check actual size
is( $share->length, 10000, '... check data length' );

# Retrieve value
is( $share->fetch, 'X' x 10000, '... fetch and compare' );

# Check number of segments
is( $share->nsegments, 3, '... check number of segments' );

# check serial number
is( $share->serial, 3, '... check serial number' );

# set back to a zero value
ok( $share->store( 0 ), 'store zero numeric value' );

# verify we're back to one segment
is( $share->nsegments, 1, '... check number of segments' );

# unlock the segment prior to fork
ok( $share->lock(LOCK_UN), 'release exclusive lock left by create()' );

defined( $pid = fork ) or die $!;

if ($pid == 0) {
#  $share->destroy( 0 );
  for(1..1000) {
    $share->lock( LOCK_EX ) or die $!;
    $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->lock( LOCK_UN ) or die $!;
  }
  exit;
} else {
  ok( defined $pid, 'forked to cause lock contention' );
  for(1..1000) {
    $share->lock( LOCK_EX ) or die $!;
    $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->lock( LOCK_UN ) or die $!;
  } 
  wait;
  ok( 1, '... child process completed' );

  $share->lock( LOCK_SH );
  is( $share->fetch, 2000, '... check stored value' );
  is( $share->serial, 2004, '... check serial number' );
  is( $share->length, 4, '... check data length' );
  $share->lock( LOCK_UN );
}

# mark share for deletion
ok( $share->remove(), 'remove segment from the system' );

# cause undefine - test returns true to prove the script is still running
undef $share;
ok( 1, '... undefine to trigger destructor' );

# recreate the keyed seg for the next script
ok( $share = IPC::Shm::Simple->create($KEY, 256, 0660), 'create key=192' );

# set a value upon it
ok( $share->store( '7836' ), '... set a value' );

# verify that value (redundant/pedantic)
is( $share->fetch, '7836', '... confirm the value' );

