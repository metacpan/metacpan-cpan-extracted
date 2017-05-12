#!perl
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
    if $@;

all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::TrustPod' } );
