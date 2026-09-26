#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

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

# Read lib, never blib: a blib left over from an earlier `make` holds the
# modules as they were then, so a new module is silently not covered and a
# deleted one is covered twice.
#
# new, prototype, set_prototype and BUILD are what Object::Proto::Sugar
# installs in every class that uses it. Exactly those four, so that a naked
# sub of our own still fails.
my @modules = all_modules('lib');
plan tests => scalar @modules;
pod_coverage_ok($_, { also_private => [ qr/\A(?:new|prototype|set_prototype|BUILD)\z/ ] })
    for @modules;
