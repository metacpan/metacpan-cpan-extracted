#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 2;
pod_coverage_ok(
        "Devel::Walk",
        { also_private => [ qw( DEBUG VERBOSE ) ], 
        },
        "Devel::Walk, ignoring private functions",
);
pod_coverage_ok(
        "Devel::Walk::Unstorable",
        { also_private => [ qw( DEBUG VERBOSE ) ], 
        },
        "Devel::Walk::Unstorable, ignoring private functions",
);

