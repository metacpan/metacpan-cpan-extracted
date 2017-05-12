#!/usr/bin/env perl
#
# This file is part of Dist-Zilla-Plugin-NoSmartCommentsTests
#
# This software is Copyright (c) 2011 by Chris Weyl.
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

no_smart_comments_in("lib/Dist/Zilla/Plugin/NoSmartCommentsTests.pm");
no_smart_comments_in("lib/Dist/Zilla/Plugin/Test/NoSmartComments.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-load.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/develop-requires.t");
no_smart_comments_in("t/develop-requires.t~");
no_smart_comments_in("t/file-is-generated.t");
no_smart_comments_in("t/file-is-generated.t~");

done_testing();
