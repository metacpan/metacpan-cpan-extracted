use Test::Pod::Coverage tests => 2;

pod_coverage_ok('KeyedMutex', { also_private => [ qw/new/ ] });
pod_coverage_ok('KeyedMutex::Lock');

