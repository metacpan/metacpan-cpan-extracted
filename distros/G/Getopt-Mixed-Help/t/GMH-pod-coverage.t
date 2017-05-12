# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl GMH-pod-coverage.t'
# Without Makefile it could be called with `perl -I../lib GMH-pod-coverage.t'

#########################################################################

use Test::More;

eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing pod coverage' if $@;
all_pod_coverage_ok();
