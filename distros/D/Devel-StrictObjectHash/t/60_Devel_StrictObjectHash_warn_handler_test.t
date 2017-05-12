#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { 
    unshift @INC => qw(test_lib t/test_lib);
    use_ok('Devel::StrictObjectHash', (
                        strict_bless => [ qw(TestBase) ], 
                        error_handling => "warn"
                        ));
}

# -----------------------------------------------------------------------------
# This test demostrates the following things:
# -----------------------------------------------------------------------------
#
# -----------------------------------------------------------------------------

# plan for this test:
# -----------------------------------------------------------------------------
# Test for warnings instead of it die-ing