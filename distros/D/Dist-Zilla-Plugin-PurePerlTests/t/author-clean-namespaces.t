
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CleanNamespaces 0.006

use Test::More 0.94;
use Test::CleanNamespaces 0.15;

subtest all_namespaces_clean => sub { all_namespaces_clean() };

done_testing;
