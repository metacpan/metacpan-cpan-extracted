#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for author testing');
  }
}

use Test::More;

eval "use Test::Pod::Coverage";
if ( $@ ) {
  plan skip_all => 'Test::Pod::Coverage required for testing POD';
}
else {
  all_pod_coverage_ok();;
}


