#!/usr/bin/perl

use strict;
use Test::More;

plan( skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.' )
    unless $ENV{TEST_AUTHOR};

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import()
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
