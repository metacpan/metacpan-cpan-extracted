#!/usr/bin/perl

use strict;
use Test::More;

BEGIN {
    plan( skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.' )
        unless $ENV{TEST_AUTHOR};
}

eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;
all_pod_files_ok();

