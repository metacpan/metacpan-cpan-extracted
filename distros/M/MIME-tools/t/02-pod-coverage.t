use Test::More;

plan skip_all => 'Test::Pod::Coverage disabled. TEST_POD_COVERAGE=1 if you want it.' unless $ENV{TEST_POD_COVERAGE};
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok();
