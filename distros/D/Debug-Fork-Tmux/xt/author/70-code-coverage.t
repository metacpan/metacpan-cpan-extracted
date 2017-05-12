#!/usr/bin/perl -w
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
# test for tests coverage

use strict;
use warnings;
use Test::More;

eval 'use Test::Strict';    ## no critic
plan skip_all => 'Test::Strict is required' if $@;

# tweak this to change coverage acceptance level
my $coverage_threshold = 70;

# shut up warnings from Devel::Cover
$ENV{DEVEL_COVER_OPTIONS} = '-silent,1';
all_cover_ok( $coverage_threshold, 't' );

