#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Exception qw(dies lives);

use Dev::Util::Syntax;
use Dev::Util::Sem  qw(:all);
use Dev::Util::File qw(:all);

use IO::Handle;

plan tests => 16;

#======================================#
#     _get_locks_dir - setup dirs      #
#======================================#

my $lock_filename = 'dev-util-sem.sem';

my $expected_dir;
my $existing_dir      = mk_temp_dir();
my $existing_dir_name = dir_suffix_slash($existing_dir);
my $non_existing_dir  = dir_suffix_slash('/xyzzy');
is( dir_exists($existing_dir_name), 1, "Dir $existing_dir should exist" );
is( dir_exists($non_existing_dir),  0, "Dir /xyzzy should not exist" );

#======================================#
#    _get_locks_dir - existing dir     #
#======================================#

my $lockdir
    = Dev::Util::Sem::_get_locks_dir( $existing_dir_name . $lock_filename );
is( $lockdir, $existing_dir_name, "Should return existing dir" );

#======================================#
#  _get_locks_dir - non-existing dir   #
#======================================#

if ( dir_writable('/var/lock') ) {
    $expected_dir = '/var/lock/';
}
elsif ( dir_writable('/var/locks') ) {
    $expected_dir = '/var/locks/';
}
elsif ( dir_writable('/run/lock') ) {
    $expected_dir = '/run/lock/';
}
elsif ( dir_writable('/tmp') ) {
    $expected_dir = '/tmp/';
}
else {
    fail('Could not find a writable dir to make lock.');
}

my $lockdir2
    = Dev::Util::Sem::_get_locks_dir( $non_existing_dir . $lock_filename );
is( $lockdir2, $expected_dir, "Should return first existing dir" );

#======================================#
#     _get_locks_dir - no lockfile     #
#======================================#
my $lockdir3 = Dev::Util::Sem::_get_locks_dir();

#======================================#
#          new - no file spec          #
#======================================#
like(
       dies {
           my $badsem = Dev::Util::Sem->new();
       },
       qr{What filespec\?},
       "Fails when no lock file spec is given"
    );

#======================================#
#          new - w/ temp dir           #
#======================================#

is( file_exists( $existing_dir_name . $lock_filename ),
    0, "Lockfile should not exist yet" );

my $sem = Dev::Util::Sem->new( $existing_dir_name . $lock_filename, 30 );

is( file_exists( $existing_dir_name . $lock_filename ),
    1, "Lockfile should exist now" );

$sem->unlock;

is( file_exists( $existing_dir_name . $lock_filename ),
    0, "Lockfile should be gone now via unlock" );

#======================================#
#         new - w/ default dir         #
#======================================#

if ( file_exists( $expected_dir . $lock_filename ) ) {
    unlink( $expected_dir . $lock_filename )
        or Carp::carp("Could not unlink file\n");
}

is( file_exists( $expected_dir . $lock_filename ),
    0, "Lockfile in default dir should not exist yet" );

my $sem2 = Dev::Util::Sem->new($lock_filename);

is( file_exists( $expected_dir . $lock_filename ),
    1, "Lockfile in default dir should exist now" );

$sem2->unlock;

is( file_exists( $expected_dir . $lock_filename ),
    0, "Lockfile in default dir should be gone now via unlock" );

#======================================#
#        second sem should fail        #
#======================================#
my $semA = Dev::Util::Sem->new( $lock_filename, 3 );
is( file_exists( $expected_dir . $lock_filename ),
    1, "Lockfile in default dir should exist now" );
is( file_is_empty( $expected_dir . $lock_filename ),
    1, "Lockfile should be empty" );

$semA->{ fh }->autoflush();
$semA->{ fh }->print("Now is the time for all good men...");
is( file_size_equals( $expected_dir . $lock_filename, 35 ),
    1, "Lockfile should be 35 characters" );

like(
       dies {
           my $semB = Dev::Util::Sem->new( $lock_filename, 1 );
           $semB->{ fh }->autoflush();
           $semB->{ fh }->print("to come to the aid of their country!");
       },
       qr{Timeout aquiring the lock},
       "Fails when lock file is locked"
    );

$semA->unlock;

is( file_exists( $expected_dir . $lock_filename ),
    0, "Lockfile in default dir should be gone now via unlock" );

done_testing;

