#!perl
#
# This file is part of Dist-Zilla-Plugin-Travis-ConfigForReleaseBranch
#
# This software is Copyright (c) 2017, 2015, 2013 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Test::More;

eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing minimum versions"
  if $@;
all_minimum_version_ok( qq{5.008008} );
