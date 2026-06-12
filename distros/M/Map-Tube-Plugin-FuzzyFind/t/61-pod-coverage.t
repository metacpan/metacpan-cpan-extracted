#!perl
use 5.010;
use Test::More 0.82;
eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'for authors only -- define $ENV{AUTHOR_TESTING}' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage' if $@;

all_pod_coverage_ok( );

done_testing( );
