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

eval 'use Test::DistManifest';
plan skip_all => "Test::DistManifest required for testing the manifest"
  if $@;

manifest_ok();
