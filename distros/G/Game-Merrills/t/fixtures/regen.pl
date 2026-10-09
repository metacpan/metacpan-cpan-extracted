#!perl

use 5.010;
use strict;
use warnings;
use lib 'lib';

use Game::Merrills;
use Game::Merrills::Bot;

# Regenerates the fixture games in t/fixtures. Run it from the distribution
# root:
#
#     perl t/fixtures/regen.pl
#
# These are REGRESSION fixtures. They were played by this distribution's own
# bot, so they prove that a game recorded today replays to the same position
# tomorrow, and nothing about whether the rules are right. The rules are
# checked in t/04 to t/11 against positions worked out by hand, and the move
# generator against counts worked out by hand in t/20-perft.t.
#
# Regenerating them is a deliberate act: if a change to the engine or the bot
# alters these games, t/19-replay.t fails first, and the question to answer is
# whether the change was meant. Only then is this script run again.

my @GAME = (
	{ file => 'level-1.txt', white => { level => 1, seed => 1 }, black => { level => 1, seed => 2 } },
	{ file => 'level-2.txt', white => { level => 2, seed => 3 }, black => { level => 2, seed => 4 } },
	{ file => 'level-3.txt', white => { level => 3, seed => 5 }, black => { level => 2, seed => 6 } },
	{
		file => 'from-a-position.txt',
		position => 'W.WWWW....B...B..BB.B... w 0 0 1 4',
		white => { level => 2, seed => 7 },
		black => { level => 1, seed => 8 },
	},
);

for my $spec (@GAME) {
	my %bot = map { $_ => Game::Merrills::Bot->new(%{ $spec->{$_} }) } qw/white black/;
	my $game = Game::Merrills->new($spec->{position} ? (position => $spec->{position}) : ());
	while ($game->status eq 'active') {
		$game->move($bot{ $game->turn }->choose($game));
	}
	my $path = "t/fixtures/$spec->{file}";
	open my $handle, '>', $path or die "cannot write $path: $!";
	print {$handle} $game->to_text;
	printf {$handle} "# %s\n# %s\n# %d\n", $game->result->stringify, $game->to_position, $game->ply;
	close $handle;
	printf "%-22s %3d plies  %s\n", $spec->{file}, $game->ply, $game->result->stringify;
}
