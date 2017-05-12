#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan skip_all => 'for authors only -- define $ENV{AUTHOR_TESTING}' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
eval 'use Test::Version qw( version_all_ok ), { is_strict => 0, has_version => 1, }';
plan skip_all => 'Test::Version required for this test' if $@;
version_all_ok();
done_testing;
