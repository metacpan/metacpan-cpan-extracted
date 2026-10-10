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

# THE STOCK all_pod_coverage_ok() IS NOT USED HERE. It walks blib and finds
# Game::RoyalUr::Install::Files, which ExtUtils::Depends generates at build
# time and which has no POD and should have none. The modules are named, so a
# new one must be added here to be graded, and t/00-load.t loads the same list.
#
# An attribute declared with `has` is a method and is counted. What is excluded
# is exactly what Object::Proto::Sugar installs or calls for itself, and nothing
# else: every other name must be documented.
my @modules = qw(
    Game::RoyalUr
    Game::RoyalUr::Engine
    Game::RoyalUr::Dice
    Game::RoyalUr::Move
    Game::RoyalUr::Notation
    Game::RoyalUr::Rules
    Game::RoyalUr::Variant
    Game::RoyalUr::Error
    Game::RoyalUr::Result
    Game::RoyalUr::Bot
    Game::RoyalUr::Terminal
);

plan tests => scalar @modules;

pod_coverage_ok($_, { also_private => [ qr/\A(?:new|prototype|set_prototype|BUILD|DEMOLISH)\z/ ] })
    for @modules;
