#!/usr/bin/env perl -w

use strict;

eval 'use Test::More';
if ($@) {
  eval 'use Test; plan tests => 1;';
  skip('Test::More is required for testing POD coverage',);
} else {
  require Test::More;
  eval 'use Test::Pod::Coverage 1.00';
  if ($@) {
    plan ('skip_all' => 'Test::Pod::Coverage is required for testing POD coverage');
  } else {
    plan ('tests' => 1);
  # all_pod_coverage_ok();

    my $trustme = { trustme => [qr/^(mastermind)$/] };
    pod_coverage_ok( "FindBin::Real", $trustme );
  }
}