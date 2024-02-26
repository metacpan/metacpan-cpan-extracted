#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan skip_all => "These tests are for authors only!" unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING}; 

plan tests => 1;

pod_coverage_ok(
        "IPC::ForkPipe",
        { also_private => [ ]
        },
        "IPC::ForkPipe, ignoring private functions",
);

