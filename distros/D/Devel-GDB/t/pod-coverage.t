use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 2;
pod_coverage_ok( "Devel::GDB" );
pod_coverage_ok( "Devel::GDB::LowLevel" );
