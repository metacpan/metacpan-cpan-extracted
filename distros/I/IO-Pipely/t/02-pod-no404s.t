#!/usr/bin/perl -w
# vim: ts=2 sw=2 filetype=perl expandtab

# Tests POD for 404 links

use strict;
use Test::More;

BEGIN {
  unless ($ENV{RUN_NETWORK_TESTS}) {
    plan skip_all => 'RUN_NETWORK_TESTS environment variable is not true.';
  }

  unless ( $ENV{RELEASE_TESTING} ) {
    plan skip_all => 'RELEASE_TESTING environment variable is not true.';
  }

  foreach my $req (qw(Test::Pod::No404s)) {
    eval "use $req";
    if ($@) {
      plan skip_all => "$req is needed for these tests.";
    }
  }
}

all_pod_files_ok();
