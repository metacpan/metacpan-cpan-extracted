
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::More;

eval 'use Test::CleanNamespaces;';
plan skip_all => 'Test::CleanNamespaces not installed' if $@;

my $fn = Test::CleanNamespaces->build_all_namespaces_clean;
$fn->();

done_testing;
