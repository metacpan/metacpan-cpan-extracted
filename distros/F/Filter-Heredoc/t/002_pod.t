#!perl

use strict;
use warnings;
use Test::More;

my $min_pod = 1.22;  # Ensure a recent version of Test::Pod

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Pod $min_pod";
plan skip_all => "Test::Pod $min_pod required for testing POD" if $@;

all_pod_files_ok();
