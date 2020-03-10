#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print "1..0 # SKIP these tests are for release candidate testing";
        exit;
    }
}

use strict;
use warnings;

use Test::More;

eval 'use Test::CPAN::Meta';
plan skip_all => "Test::CPAN::Meta required for testing the meta"
  if $@;

meta_yaml_ok();
