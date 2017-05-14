#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

TODO: {
  plan tests => 1;
  local $TODO = "make pod coverage not horrible";
  fail;
}

#  all_pod_coverage_ok({
#    coverage_class => 'Pod::Coverage::CountParents',
#  });
