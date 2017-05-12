#!/usr/bin/env perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;
unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

use Test::MinimumVersion;
all_minimum_version_ok('v5.10.1');
