#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => "\$ENV{RELEASE_TESTING} required for these tests" if(!$ENV{RELEASE_TESTING});

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 1;

pod_coverage_ok('IO::Stty', "IO::Stty pod coverage");
