
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

eval "use Pod::Coverage::Moose 0.02";
plan skip_all => "Pod::Coverage::Moose 0.02 required for testing POD coverage"
    if $@;

all_pod_coverage_ok(
    {
        coverage_class => 'Pod::Coverage::Moose',
        trustme        => [qr/^(?:BUILD|insert_many|update|delete)$/]
    }
);
