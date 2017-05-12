#!perl
#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing minimum versions"
  if $@;
all_minimum_version_from_metayml_ok();
