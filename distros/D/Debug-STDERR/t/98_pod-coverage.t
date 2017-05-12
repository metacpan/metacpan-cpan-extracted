use strict;
use Test::More;
BEGIN {
  unless ( !$ENV{TEST_POD} ) {

    plan skip_all => "Enable TEST_POD environment variable to test POD";
  }
  else {
    eval "use Test::Pod::Coverage";
    plan skip_all =>
      "Test::Pod::Coverage required for testting pod coverage"
      if $@;
    Test::Pod::Coverage::all_pod_coverage_ok();
  }
}
