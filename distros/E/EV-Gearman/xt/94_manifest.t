#!/usr/bin/env perl
# Author test: MANIFEST is in sync with the working tree — nothing
# listed is missing from disk, and nothing on disk (after MANIFEST.SKIP)
# is left out of MANIFEST. Catches the easy mistake of adding a file
# and forgetting to list it. Uses core ExtUtils::Manifest, which honors
# MANIFEST.SKIP (so build artifacts are ignored).
use strict;
use warnings;
use Test::More;
use ExtUtils::Manifest qw(fullcheck);

plan skip_all => 'no MANIFEST here' unless -f 'MANIFEST';
plan tests => 2;

local $ExtUtils::Manifest::Quiet = 1;
my ($missing, $extra) = fullcheck();

is_deeply $missing, [], 'every file in MANIFEST exists on disk'
    or diag "missing from disk: @$missing";
is_deeply $extra, [], 'every non-skipped file on disk is in MANIFEST'
    or diag "on disk but not in MANIFEST: @$extra";
