#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.032

use Test::Pod::No404s;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

all_pod_files_ok();
