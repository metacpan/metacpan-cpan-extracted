use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD" if $@;
plan tests => 1;
pod_coverage_ok(Locale::SubCountry, 'Coverage OK for Locale::SubCountry');
