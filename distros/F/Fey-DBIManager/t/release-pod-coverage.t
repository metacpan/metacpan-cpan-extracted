
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04; use Pod::Coverage::Moose";
plan skip_all => "Test::Pod::Coverage 1.04 and Pod::Coverage::Moose are required for testing POD coverage"
    if $@;

all_pod_coverage_ok(
    {
        coverage_class => 'Pod::Coverage::Moose',
        trustme        => [qr/^BUILD$/],
    }
);
