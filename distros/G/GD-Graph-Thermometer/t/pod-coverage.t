#!/usr/bin/perl -Tw

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

# all_pod_coverage_ok(
#   "GD::Graph::Thermometer",
#  { also_private => [ qr/^_/ ], },
#   "GD::Graph::Thermometer, _functions are private",
# );

all_pod_coverage_ok();

1;
