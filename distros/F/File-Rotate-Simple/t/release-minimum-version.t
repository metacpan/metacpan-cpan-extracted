#!/usr/bin/env perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

use Test::MinimumVersion;
all_minimum_version_ok('v5.8.8');
