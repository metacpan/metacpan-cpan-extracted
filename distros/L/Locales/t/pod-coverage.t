#!perl

use lib 'lib', '../lib';
use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod::Coverage 1.04';
plan $@ ? ( 'skip_all' => 'Test::Pod::Coverage 1.04 required for testing POD coverage' ) : ( 'tests' => 1 );
pod_coverage_ok( "Locales", "Locales.pm is covered" );

# We don't really need POD for the mods that are essentially a databases
# all_pod_coverage_ok();
