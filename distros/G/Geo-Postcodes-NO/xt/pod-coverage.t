use strict;
use warnings;

use Test::More;

plan skip_all => 'Author test; set AUTHOR_TESTING=1 to run'
    unless $ENV{AUTHOR_TESTING};

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage' if $@;

all_pod_coverage_ok();
