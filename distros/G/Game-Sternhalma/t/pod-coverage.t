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

# NAMED, not all_pod_coverage_ok: a module left off this list is a module whose
# POD nobody is grading, and a list makes that a diff.
my @modules = qw(
    Game::Sternhalma
    Game::Sternhalma::Bot
    Game::Sternhalma::Engine
    Game::Sternhalma::Error
    Game::Sternhalma::Layout
    Game::Sternhalma::Notation
    Game::Sternhalma::Result
    Game::Sternhalma::Terminal
);

plan tests => scalar @modules;

# An Object::Proto::Sugar class gets these four from the keyword.
# Every other accessor is ours to document.
pod_coverage_ok($_, { also_private => [ qr/\A(?:new|prototype|set_prototype|BUILD)\z/ ] })
    for @modules;
