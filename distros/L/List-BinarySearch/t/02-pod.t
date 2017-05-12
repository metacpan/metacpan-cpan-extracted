#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod

my $min_tp = 1.22;
eval "use Test::Pod $min_tp;"; ## no critic (eval)
if( $@ || ! $ENV{RELEASE_TESTING} ) {
  plan skip_all =>
  "Test::Pod $min_tp required, and \$ENV{RELEASE_TESTING} must be set for "
  . "POD tests.";
  exit(0);
}

all_pod_files_ok();
