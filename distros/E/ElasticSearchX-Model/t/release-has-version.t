#!perl
#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2018 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use Test::More;

eval "use Test::HasVersion";
plan skip_all => "Test::HasVersion required for testing version numbers"
  if $@;
all_pm_version_ok();
