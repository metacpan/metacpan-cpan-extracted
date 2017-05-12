use Test::More;
eval "use Test::Pod::Coverage tests=>1";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage"
    if $@;

pod_coverage_ok( "HTML::StripScripts", "HTML::StripScripts is covered" );
