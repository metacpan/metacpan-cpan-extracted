#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod 1.14';
plan $@ ? ( 'skip_all' => 'Test::Pod 1.14 required for testing POD coverage' ) : ( 'tests' => 1 );
use Locales;
pod_file_ok( $INC{'Locales.pm'}, "Locales.pm is covered" );

# We don't really need POD for the mods that are essentially a databases
# all_pod_files_ok();
