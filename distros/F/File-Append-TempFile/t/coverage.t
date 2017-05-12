# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl coverage.t'

use Test::More;
eval 'use Test::Pod::Coverage tests => 1';
plan skip_all => 'Test::Pod::Coverage not found' if $@;
pod_coverage_ok('File::Append::TempFile');
