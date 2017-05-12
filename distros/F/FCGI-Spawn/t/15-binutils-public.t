#!/usr/bin/env perl
# Test BinUtils public suid subroutines.
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Import better perlvars
use English qw/$EUID $UID $EGID $GID/;

# Requires root user
plan( 'skip_all' => "Current user id is $EUID. This test requires uid == 0", )
    if $EUID;

# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Loads main app module
use_ok('FCGI::Spawn::BinUtils');

# Handles exceptions
use Test::Exception;

# Concatenates directories
use File::Spec;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# User id to switch to for tests
const my $TEST_USER_ID => defined( $ENV{'TEST_USER_ID'} )
    ? $ENV{'TEST_USER_ID'}
    : 12345;

# Group id to switch to for tests
const my $TEST_GROUP_ID => defined( $ENV{'TEST_GROUP_ID'} )
    ? $ENV{'TEST_GROUP_ID'}
    : 12345;

# Socket name to check for unexistence
# Requires  :   File::Spec
const my $SPAWNER_SOCK => File::Spec->catfile( '', 'tmp' => 'spawner.sock' );

### MAIN ###
# Require   :   Test::Most, Test::Exception, English, FCGI::Spawn::BinUtils,
#               POSIX modules
#
# Check for default socket name file to not exist or for being removed
plan( 'skip_all' =>
          "The file '$SPAWNER_SOCK' exists and can not be removed: '$!'. "
        . " Please remove this file before running these tests.", )
    if ( -e $SPAWNER_SOCK )
    and not( unlink $SPAWNER_SOCK );

# Catch exception
lives_and {

    # Set user id and  group id
    FCGI::Spawn::BinUtils::set_uid_gid( $TEST_USER_ID => $TEST_GROUP_ID );

    # Test if user id and  group id were set
    is( $UID  => $TEST_USER_ID, "Real user set to $TEST_USER_ID" );
    is( $EUID => $TEST_USER_ID, "Effective user set to $TEST_USER_ID" );
    is( $GID => "$TEST_GROUP_ID $TEST_GROUP_ID",
        "Real group set to $TEST_GROUP_ID",
    );
    is( $EGID => "$TEST_GROUP_ID $TEST_GROUP_ID",
        "Effective group set to $TEST_GROUP_ID",
    );

}
'Switch user id and group id';

# Continues till this point
done_testing();
