#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ($ENV{AUTHOR_TESTING}) {
	plan skip_all => 'Author tests not required for installation';
}

use Game::Checkers;
use Game::Checkers::Rules;

# The deep end of the ladder t/20-perft.t checks the shallow end of: Aart Bik's
# numbers for 8x8 English draughts from the starting position, posted in "perft
# for 8x8 checkers" on TalkChess, https://talkchess.com/viewtopic.php?t=27814
#
# Depth 9 is about twenty seconds in pure Perl and depth 10 about two minutes,
# so 10 waits for CHECKERS_PERFT_10. Neither is timed: the depth is the bound.
my @PUBLISHED = (
	[6, 36_768],
	[7, 179_740],
	[8, 845_931],
	[9, 3_963_680],
);
push @PUBLISHED, [10, 18_391_564] if $ENV{CHECKERS_PERFT_10};

plan tests => scalar @PUBLISHED;

sub perft {
	my ($position, $turn, $depth) = @_;
	my $moves = Game::Checkers::Rules::generate($position, $turn);
	return scalar @{$moves} if $depth <= 1;
	my $nodes = 0;
	my $next = $turn eq 'black' ? 'white' : 'black';
	for my $raw (@{$moves}) {
		Game::Checkers::Rules::apply($position, $raw);
		$nodes += perft($position, $next, $depth - 1);
		Game::Checkers::Rules::unapply($position, $raw);
	}
	return $nodes;
}

my $position = [@{Game::Checkers->new->board->position}];
for my $line (@PUBLISHED) {
	my ($depth, $nodes) = @{$line};
	is perft($position, 'black', $depth), $nodes, "perft($depth) is $nodes";
}
