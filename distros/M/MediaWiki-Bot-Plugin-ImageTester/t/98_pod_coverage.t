use Test::More;
BEGIN{push @INC, "./lib"}
eval "use Test::Pod::Coverage tests=>1";
plan( skip_all => "Test::Pod 1.00 required for testing POD") if $@;
pod_coverage_ok( "MediaWiki::Bot::Plugin::ImageTester", "ImageTester is covered" );
