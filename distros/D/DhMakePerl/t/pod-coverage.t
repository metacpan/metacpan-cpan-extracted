use strict;
use warnings;
use Test::More;

plan skip_all => "This is a release-time test" unless $ENV{RELEASE_TESTING};

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my @modules = all_modules();

plan tests => scalar(@modules);

for (@modules) {
SKIP: {
        skip "Command::Packaging needs documenting", 1, if $_ eq 'DhMakePerl::Command::Packaging';
        skip "Command::make needs documenting", 1, if $_ eq 'DhMakePerl::Command::make';
        pod_coverage_ok( $_,
            { coverage_class => 'Pod::Coverage::CountParents' } );
    }
}
