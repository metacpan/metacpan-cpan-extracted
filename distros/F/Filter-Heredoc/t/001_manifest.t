#!perl

use strict;
use warnings;
use Test::More;

my $min_manifest = 0.9;  # Ensure a recent version of Test::CheckManifest

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest $min_manifest";
plan skip_all => "Test::CheckManifest $min_manifest required" if $@;

ok_manifest();
