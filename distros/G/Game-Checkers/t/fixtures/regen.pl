#!perl

use 5.010;
use strict;
use warnings;
use lib 'lib';

use Game::Checkers;
use Game::Checkers::Bot;

# Regenerates the fixture games in t/fixtures. Run it from the distribution
# root:
#
#     perl t/fixtures/regen.pl
#
# These are REGRESSION fixtures. They were played by this distribution's own
# bot, so they prove that a game recorded today replays to the same position
# tomorrow, and nothing about whether the rules are right. The rules are
# checked in t/04 to t/11 against positions worked out by hand, and the move
# generator against a published perft table in t/20-perft.t.
#
# Regenerating them is a deliberate act: if a change to the engine or the bot
# alters these games, t/19-replay.t fails first, and the question to answer is
# whether the change was meant. Only then is this script run again.

my @GAME = (
	{
		file => 'level-3.pdn',
		event => 'Bot against bot, level 3',
		black => { level => 3, seed => 1 },
		white => { level => 3, seed => 2 },
	},
	{
		file => 'level-4.pdn',
		event => 'Bot against bot, level 4',
		black => { level => 4, seed => 3 },
		white => { level => 4, seed => 4 },
	},
);

for my $spec (@GAME) {
	my $game = Game::Checkers->new;
	my %bot = map { $_ => Game::Checkers::Bot->new(%{$spec->{$_}}) } qw/black white/;

	while ($game->status eq 'active' && $game->ply < 200) {
		$game->move($bot{$game->turn}->choose($game));
	}

	my $path = 't/fixtures/' . $spec->{file};
	open my $handle, '>', $path or die "cannot write $path: $!";
	print {$handle} $game->to_pdn(
		Event => $spec->{event},
		Site => 'Game::Checkers ' . $Game::Checkers::VERSION,
		Date => '2026.09.13',
		Black => "Bot level $spec->{black}{level} seed $spec->{black}{seed}",
		White => "Bot level $spec->{white}{level} seed $spec->{white}{seed}"
	);
	close $handle;

	printf "%s: %d plies, %s\n", $path, $game->ply,
		$game->result ? $game->result->stringify : 'unfinished';
}
