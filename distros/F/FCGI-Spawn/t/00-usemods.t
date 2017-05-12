#!/usr/bin/env perl
# Test modules loading
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Test strictures
use Test::Strict;

# Concatenates directories
use File::Spec;

# Loads main app module
# use Your::Module;

# Catches exceptions
# use Try::Tiny;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Socket name to check for unexistence
# Requires  :   File::Spec
const my $SPAWNER_SOCK => File::Spec->catfile( '', 'tmp' => 'spawner.sock' );

# Test for 'use warnings;', too
$Test::Strict::TEST_WARNINGS = 1;

### MAIN ###
# Require   :   Test::Strict, Test::Most
#
# Check for default socket name file to not exist or for being removed
plan( 'skip_all' =>
          "The file '$SPAWNER_SOCK' exists and can not be removed: '$!'. "
        . " Please remove this file before running these tests.", )
    if ( -e $SPAWNER_SOCK )
    and not( unlink $SPAWNER_SOCK );

# Check loadability of the every module
all_perl_files_ok()

    # Continues till this point
    # done_testing();
