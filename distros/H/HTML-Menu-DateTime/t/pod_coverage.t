use strict;
use Test::More;

SKIP: {
  eval "use Test::Pod::Coverage 1.00";
  
  if ($@) {
    plan tests => 1;
    skip "Test::Pod::Coverage not installed", 1;
  }
  
  all_pod_coverage_ok();
}
