#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Release tests not required for installation" );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
## no critic
eval "use Test::Pod $min_tp";
## use critic
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
