#!/usr/bin/env perl
#
# This file is part of Dist-Zilla-Plugin-Travis-ConfigForReleaseBranch
#
# This software is Copyright (c) 2017, 2015, 2013 by Chris Weyl.
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

no_smart_comments_in("lib/Dist/Zilla/Plugin/Travis/ConfigForReleaseBranch.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");

done_testing();
