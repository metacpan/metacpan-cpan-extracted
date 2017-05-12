#!perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
if (not $ENV{TEST_AUTHOR}) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to run.';
    plan skip_all => $msg;
}
eval "use Test::ConsistentVersion";
plan skip_all => "Test::ConsistentVersion required for tests" if $@;

Test::ConsistentVersion::check_consistent_versions();
