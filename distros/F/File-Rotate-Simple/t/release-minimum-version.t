#!/usr/bin/env perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use Test::More;

use Test::MinimumVersion;
all_minimum_version_ok('v5.8.8');
