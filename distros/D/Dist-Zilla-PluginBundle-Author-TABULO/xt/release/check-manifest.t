#!perl -T

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;

eval "use Test::CheckManifest 1.24";
plan skip_all => "Test::CheckManifest 1.24 required for testing MANIFEST"
  if $@;

ok_manifest();
