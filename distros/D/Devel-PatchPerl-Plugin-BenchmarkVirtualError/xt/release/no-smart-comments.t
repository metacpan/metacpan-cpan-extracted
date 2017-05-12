#!/usr/bin/env perl
#
# This file is part of Devel-PatchPerl-Plugin-BenchmarkVirtualError
#
# This software is Copyright (c) 2015 by DreamHost, Inc.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::NoSmartComments";
plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
    if $@;

no_smart_comments_in("lib/Devel/PatchPerl/Plugin/BenchmarkVirtualError.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");

done_testing();
