#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Rules;
use Game::Oware::Variant ();

# THE ONLY EXACT EXTERNAL ORACLE THIS DISTRIBUTION COULD EVER HAVE.
#
#   Awari game score database
#   John W. Romein (creator), Henri E. Bal, Kees Verstoep
#   Vrije Universiteit Amsterdam, 2024
#   DOI 10.48338/vu01-11wjke, CC-BY 4.0
#   https://research.vu.nl/en/datasets/awari-game-score-database
#
# Every byte in scores.<SEEDS> is a value between -48 and 48: the difference in
# seeds the player to move can still score with optimal play. That is a
# per-position answer computed by somebody who was not writing this code, over
# the whole 889,063,398,406-position game.
#
# IT LIVES IN xt AND IT NEEDS A DOWNLOAD. The low-seed subset, scores.0-20.tar.gz,
# is 95MB; the full set is over 800GB. A file that size cannot ship in a CPAN
# distribution, so this test skips without it - and plan_game_oware/10 counts
# that skip as a MISS rather than a pass, because a fallback that reports PASS
# is a failing test wearing a green tick.
#
# WHAT IS STILL NOT PINNED, and why this test must stay away from it:
#
# The dataset pins the grand slam rule and nothing else. Its Awari-Python/
# README.md says the scores are computed under rules where "it is not allowed to
# remove all stones of the opponent (leaving it no move), unless it is the only
# move available", which is what Game::Oware::Variant's `awari` implements.
#
# It says NOTHING about a cycle rule, and Board.py contains no move generation
# at all - only Goedel indexing. So a position whose value depends on how a
# non-terminating game is scored is a position where this engine and the
# database may legitimately disagree, and comparing them there would be
# comparing two different games.
#
# WHAT WHOEVER FINISHES THIS HAS TO BUILD:
#
#  1. the Goedel numbering, ported from Awari-Python/binomium.py and
#     goedels.py. It is a combinatorial index, not a hash, and goedels.py is
#     117K of generated tables.
#  2. the database coding's own constraint: it OMITS unreachable positions, on
#     the grounds that "the opponent always has at least one empty pit (except
#     for the starting position), since in the previous turn it must have
#     emptied one". A position that does not satisfy that cannot be looked up
#     at all, and GoedelNumber returns -1 for it.
#  3. a comparison that reads the database value as a FUTURE differential from
#     the board alone. The database has no stores in it; seeds already captured
#     are not part of the position.
#
# Until that exists this file states the oracle, states its terms, and skips.

my $path = $ENV{AWARI_PATH};

plan(skip_all => 'set AWARI_PATH to a directory holding the Awari score '
	. 'database (scores.0-20.tar.gz from DOI 10.48338/vu01-11wjke, CC-BY 4.0) '
	. 'to run the external oracle; see the header of this file for what is '
	. 'still to be built')
	unless defined $path && -d $path;

plan(skip_all => "AWARI_PATH is set to $path but holds no scores.<N> files")
	unless glob("$path/scores.*");

# The Goedel indexing is not implemented, so nothing below can run yet. This is
# deliberately a failure rather than a skip once the database IS present: if
# somebody went to the trouble of fetching 95MB, silently doing nothing with it
# is the worst of the available outcomes.
fail('the Awari database is present but the Goedel indexing is not implemented');
diag('see the header of xt/awari-oracle.t for the three pieces still needed');

subtest 'the variant this oracle is for is the one that is shipped' => sub {
	is(Game::Oware::Variant::grand_slam('awari'), 'illegal_unless_only',
		'awari implements the rule the dataset README pins');

	# The rule, exercised rather than asserted: a slam is filtered out when
	# another move exists and played when it is the only one.
	my $choice = [ 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 21, 24 ];
	my $only   = [ 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 22, 24 ];

	is_deeply([ Game::Oware::Rules->legal_moves($choice, 'p1', 'awari') ], [ 0 ],
		'not allowed to remove all stones of the opponent');
	is_deeply([ Game::Oware::Rules->legal_moves($only, 'p1', 'awari') ], [ 5 ],
		'unless it is the only move available');
};

done_testing;
