#!perl -T

use Test::More;
eval 'use Test::Pod::Coverage 1.04 tests => 1';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;
pod_coverage_ok('Getopt::Euclid', 'Getopt::Euclid\'s POD is covered');
