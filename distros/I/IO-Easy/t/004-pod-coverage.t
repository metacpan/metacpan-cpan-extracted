#!/usr/bin/perl

use Class::Easy;

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
	if $@;

plan tests => 3;
pod_coverage_ok( "IO::Easy");
pod_coverage_ok( "IO::Easy::Dir");
pod_coverage_ok( "IO::Easy::File");
