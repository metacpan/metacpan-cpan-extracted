#!/usr/bin/env perl
#
# This file is part of Dist-Zilla-PluginBundle-RSRCHBOY
#
# This software is Copyright (c) 2026 by Chris Weyl.
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

no_smart_comments_in("lib/Dist/Zilla/PluginBundle/RSRCHBOY.pm");
no_smart_comments_in("lib/Pod/Weaver/PluginBundle/RSRCHBOY.pm");
no_smart_comments_in("lib/Pod/Weaver/Section/RSRCHBOY/Authors.pm");
no_smart_comments_in("lib/Pod/Weaver/Section/RSRCHBOY/GeneratedAttributes.pm");
no_smart_comments_in("lib/Pod/Weaver/Section/RSRCHBOY/LazyAttributes.pm");
no_smart_comments_in("lib/Pod/Weaver/Section/RSRCHBOY/RequiredAttributes.pm");
no_smart_comments_in("lib/Pod/Weaver/Section/RSRCHBOY/RoleParameters.pm");
no_smart_comments_in("lib/Pod/Weaver/SectionBase/CollectWithIntro.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-load.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");

done_testing();
