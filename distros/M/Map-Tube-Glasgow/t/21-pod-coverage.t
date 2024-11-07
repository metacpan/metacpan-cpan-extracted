#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage' if $@;

all_pod_coverage_ok( );
