#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;

# all_pod_coverage_ok();
# there is AFACT no everything-but mode to do everything but Devel::Kit::_CODE
plan tests => 3;
pod_coverage_ok('Devel::Kit');
pod_coverage_ok('Devel::Kit::TAP');
pod_coverage_ok('Devel::Kit::cPanel');
