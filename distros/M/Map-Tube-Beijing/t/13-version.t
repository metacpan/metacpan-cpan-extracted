#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
eval 'use Test::Version qw( version_all_ok ), { is_strict => 1, has_version => 1, }';
plan skip_all => 'Test::Version required for this test' if $@;
version_all_ok();
done_testing;
