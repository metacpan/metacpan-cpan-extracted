#!perl
use 5.006;
use strict;
use warnings;
use Test::More;


unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

#####
##### Had to add .exists and other files to exclude hash in Test::CheckManifest
#####

ok_manifest();
