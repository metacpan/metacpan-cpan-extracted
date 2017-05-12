#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use 5.006;
use strict;
use warnings;
use Test::More;

use Test::Requires {
    'Test::Version' => 0.04,
};

version_all_ok;
done_testing;
