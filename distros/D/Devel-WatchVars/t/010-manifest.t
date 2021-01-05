#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan(skip_all => "Author tests not required for installation");
}

require Test::CheckManifest if 0;

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
