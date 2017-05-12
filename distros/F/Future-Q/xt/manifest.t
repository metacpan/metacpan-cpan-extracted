#!perl -T

use strict;
use warnings;
use Test::More;

if(!$ENV{RELEASE_TESTING}) {
    plan skip_all => "Set RELEASE_TESTING environment to check manifest.";
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest();
