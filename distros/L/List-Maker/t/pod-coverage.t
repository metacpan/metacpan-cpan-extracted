use Test::More;
eval "use Test::Pod::Coverage";

if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
}
else {
    plan 'no_plan';
}
pod_coverage_ok( 'List::Maker' );
