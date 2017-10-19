#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan skip_all => "This is a release-time test" unless $ENV{RELEASE_TESTING};

eval q{use Test::Version 1.004001 qw( version_all_ok ), {
        is_strict   => 1,
        has_version => 1,
        consistent  => 1,
        };
};
plan skip_all =>
    "Test::Version 1.004001 required for testing version numbers"
    if $@;

version_all_ok();
done_testing;
