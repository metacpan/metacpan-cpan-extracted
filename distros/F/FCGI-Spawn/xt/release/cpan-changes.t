#!/usr/bin/perl
#
# This file is part of FCGI-Spawn
#
# This software is Copyright (c) 2012 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The Lesser GPL (LGPL) License
#
#
# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::More;

# Can test Changes to conform to CPAN spec
eval 'use Test::CPAN::Changes';
plan( 'skip_all' => 'Test::CPAN::Changes required for this test' ) if $@;

### MAIN ###
# Require   :   Test::CPAN::Changes
#
# Test if Changes conform to a CPAN::Changes::Spec
changes_ok();

# Continues till this point
done_testing();
