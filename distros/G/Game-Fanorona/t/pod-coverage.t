#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# NAMED, not all_pod_coverage_ok: a module left off this list is a module whose
# POD nobody is grading, and a list makes that a diff.
my @modules = qw(
    Game::Fanorona
    Game::Fanorona::Bot
    Game::Fanorona::Engine
    Game::Fanorona::Error
    Game::Fanorona::Move
    Game::Fanorona::Notation
    Game::Fanorona::Result
    Game::Fanorona::Rules
    Game::Fanorona::Terminal
    Game::Fanorona::Variant
);

plan tests => scalar @modules;

# An Object::Proto::Sugar class gets these four from the keyword.
# Every other accessor is ours to document. No class here has a DEMOLISH:
# t/31-exceptions.t says why.
pod_coverage_ok($_, { also_private => [ qr/\A(?:new|prototype|set_prototype|BUILD)\z/ ] })
    for @modules;
