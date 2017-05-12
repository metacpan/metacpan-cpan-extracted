#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
## no critic
eval "use Test::CheckManifest $min_tcm"; # no-critic
## use critic
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
