#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


# This test is generated by Dist::Zilla::Plugin::Test::Fixme
use strict;
use warnings;

use Test::Fixme;
run_tests();
