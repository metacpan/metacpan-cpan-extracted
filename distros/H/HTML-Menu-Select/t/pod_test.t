use strict;
use Test::More;

SKIP: {
  eval "use Test::Pod 1.00";
  
  if ($@) {
    plan tests => 1;
    skip "Test::Pod not installed", 1;
  }
  
  all_pod_files_ok();
}
