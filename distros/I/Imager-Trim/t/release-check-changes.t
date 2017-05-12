#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}


use Test::More;

eval "use Test::CheckChanges";
plan skip_all => "Test::CheckChanges required for testing changes"
  if $@;
ok_changes();
