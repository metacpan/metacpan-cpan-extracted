#!/usr/bin/env perl
#
# This file is part of Dist-Zilla-Role-Store
#
# This software is Copyright (c) 2014 by Chris Weyl.
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

no_smart_comments_in_all();

done_testing();
