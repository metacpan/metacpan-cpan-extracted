#!/usr/bin/perl

#
# Test that the syntax of our POD documentation is valid.
#

use strict;
use Test::More;

# Don't run tests for installs
unless ( $ENV{RELEASE_TESTING} ) {
   plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();

