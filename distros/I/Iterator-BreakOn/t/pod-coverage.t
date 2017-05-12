#!perl -T

use Test::More;

eval "use Test::Pod::Coverage 1.04";

plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @modules = grep { $_ !~ m{(X|BreakOn|CSV)\z}xms } all_modules();

plan tests => scalar(@modules);

foreach my $module (@modules) {
    pod_coverage_ok( $module );
}

