#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval 'use Test::Version qw( version_all_ok ), { is_strict => 1, has_version => 1, }';
plan skip_all => 'Test::Version required for this test' if $@;
version_all_ok( );

done_testing( );
