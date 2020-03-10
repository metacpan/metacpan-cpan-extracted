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

eval 'use Test::CPAN::Changes';
plan skip_all => "Test::CPAN::Changes required for testing CPAN Changes"
  if $@;

changes_ok();
