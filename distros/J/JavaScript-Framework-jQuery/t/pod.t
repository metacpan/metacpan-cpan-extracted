#!perl -T

use strict;
use warnings;
use Test::More;

if ($ENV{AUTOMATED_TESTING}) {
    plan skip_all => 'AUTOMATED_TESTING is set, skipping POD tests';
}
elsif (! $ENV{TEST_POD}) {
    plan skip_all => 'Set the TEST_POD environment variable to run POD tests.';
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
