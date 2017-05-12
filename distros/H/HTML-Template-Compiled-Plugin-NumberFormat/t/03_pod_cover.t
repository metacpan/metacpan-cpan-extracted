use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "HTML::Template::Compiled::Plugin::NumberFormat", "HTC::Plugin::NumberFormat is covered");

