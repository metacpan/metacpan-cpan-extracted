
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::More;
use Test::Pod::Coverage;

all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::Moose' } );
