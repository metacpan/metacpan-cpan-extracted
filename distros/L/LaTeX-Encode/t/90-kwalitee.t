#!/usr/bin/perl
# $Id: 90-kwalitee.t 27 2012-08-30 19:54:25Z andrew $

use strict;
use Test::More;

plan( skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.' )
    unless $ENV{TEST_AUTHOR};

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [ qw( -has_meta_yml) ] );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' )
    if $@;
