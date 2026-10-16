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
# POD nobody is grading, and the last test fails on one.
my @modules = qw(
    Game::Shogi
    Game::Shogi::Bot
    Game::Shogi::Engine
    Game::Shogi::Error
    Game::Shogi::Handicap
    Game::Shogi::Move
    Game::Shogi::Notation
    Game::Shogi::Result
    Game::Shogi::Terminal
    Game::Shogi::USI
);

plan tests => scalar(@modules) + 1;

# An Object::Proto::Sugar class gets these from the keyword.
# Every other accessor is ours to document.
pod_coverage_ok($_, { also_private => [ qr/\A(?:new|prototype|set_prototype|BUILD)\z/ ] })
    for @modules;

my %listed = map { $_ => 1 } @modules;
my @unlisted = grep { !$listed{$_} }
               map  { (my $m = $_) =~ s{\Alib/}{}; $m =~ s{\.pm\z}{}; $m =~ s{/}{::}g; $m }
               glob 'lib/Game/Shogi.pm lib/Game/Shogi/*.pm';
is_deeply(\@unlisted, [], 'every module in lib is on the list') or diag("unlisted: @unlisted");
