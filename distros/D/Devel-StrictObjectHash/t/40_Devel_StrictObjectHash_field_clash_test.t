#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { 
    unshift @INC => qw(test_lib t/test_lib);
    use_ok('Devel::StrictObjectHash', (
                        strict_bless => [ qw(TestClash TestInitializerClash) ], 
                        allow_autovivification_in => qr/_init/
                        ));
}

# -----------------------------------------------------------------------------
# This test demostrates the following things:
# -----------------------------------------------------------------------------
#
# -----------------------------------------------------------------------------

# plan for this test:
# -----------------------------------------------------------------------------
# I want to create a TestClash module which will inherit TestBase and 
# then create a private name clash. Devel::StrictObjectHash should detect it 
# and report it to us.
# 
# I want to create TestInitializerClash which will inherit from TestInitializer
# and create a private field clash but TestInitializerClash will create the 
# field first and so TestInitializer will then try to overwrite it.
