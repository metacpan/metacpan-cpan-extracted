use strict;
use Test::More;

eval {
    require Test::Pod::Coverage;
};
if ($@) {
    plan skip_all => "Test::Pod::Coverage not installed";
}

Test::Pod::Coverage::all_pod_coverage_ok();
