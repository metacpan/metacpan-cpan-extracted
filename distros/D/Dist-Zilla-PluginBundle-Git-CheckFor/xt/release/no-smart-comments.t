#!/usr/bin/env perl
#
# This file is part of Dist-Zilla-PluginBundle-Git-CheckFor
#
# This software is Copyright (c) 2012 by Chris Weyl.
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

no_smart_comments_in("lib/Dist/Zilla/Plugin/Git/CheckFor/CorrectBranch.pm");
no_smart_comments_in("lib/Dist/Zilla/Plugin/Git/CheckFor/Fixups.pm");
no_smart_comments_in("lib/Dist/Zilla/Plugin/Git/CheckFor/MergeConflicts.pm");
no_smart_comments_in("lib/Dist/Zilla/PluginBundle/Git/CheckFor.pm");
no_smart_comments_in("lib/Dist/Zilla/Role/Git/Repo/More.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/funcs.pm");
no_smart_comments_in("t/plugin/correct_branch.t");
no_smart_comments_in("t/plugin/fixups.t");
no_smart_comments_in("t/role.t");

done_testing();
