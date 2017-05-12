#!perl -T
#$ENV{RELEASE_TESTING} = 1;

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

{
    ## no critic

    eval "use Test::CheckManifest 0.9";
}

plan skip_all => "Test::CheckManifest 0.9 required" if $@;

ok_manifest();
