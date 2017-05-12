use Test::More;
eval "use Test::Pod::Coverage tests=>1";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage"
    if $@;

pod_coverage_ok(
    "HTML::StripScripts::Parser",
    { trustme => ['hss_init'] },
    "HTML::StripScripts::Parser is covered"
);
