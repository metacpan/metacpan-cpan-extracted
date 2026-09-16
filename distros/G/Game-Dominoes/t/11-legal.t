#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Error;
use Game::Dominoes::Hand;
use Game::Dominoes::Tile;

plan tests => 9;

my $SEED = 'a' x 32;

sub tile { Game::Dominoes::Tile->of(@_) }

# A game whose state we set by hand, so that each refusal can be provoked
# exactly rather than hunted for across seeds.
sub rigged {
	my (%set) = @_;
	my $g = Game::Dominoes->new(seed => $SEED, players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => $set{hand} || []);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(0, 0) ]);
	$g->turn(1);
	if (my $opening = $set{opening}) {
		$g->layout->place($_->[0], $_->[1]) for @$opening;
	}
	return $g;
}

sub refusal {
	my ($out) = @_;
	return undef unless ref $out eq 'Game::Dominoes::Error';
	return $out->code;
}

# Every flag has its own subtest below, and the last subtest asserts that the
# set of flags and the set of subtests are the same. An error code nothing can
# produce is dead weight, and worse here than usual: phase 10 maps every flag
# onto a P2PGames::Game::Illegal code, so an unreachable flag becomes an
# unreachable row in a table somebody has to keep.
my %covered;

subtest 'not_your_turn' => sub {
	plan tests => 2;
	my $g = rigged(hand => [ tile(6, 4) ]);
	is refusal($g->play(2, '6-4@L')), 'not_your_turn', 'the other seat may not play';
	is refusal($g->play(99, '6-4@L')), 'not_your_turn', 'nor may a seat that does not exist';
	$covered{not_your_turn} = 1;
};

subtest 'tile_not_held' => sub {
	plan tests => 2;
	my $g = rigged(hand => [ tile(6, 4) ]);
	is refusal($g->play(1, '3-2@L')), 'tile_not_held', 'a tile the seat does not hold';
	is refusal($g->play(1, '0-0@L')), 'tile_not_held',
		'even one that another seat holds';
	$covered{tile_not_held} = 1;
};

subtest 'end_mismatch' => sub {
	plan tests => 2;
	# 6-4 down, so the ends show a six and a four. A 3-2 matches neither.
	my $g = rigged(hand => [ tile(3, 2) ], opening => [ [ tile(6, 4), 'L' ] ]);
	is refusal($g->play(1, '3-2@L')), 'end_mismatch', 'a tile matching neither end';
	is refusal($g->play(1, '3-2@R')), 'end_mismatch', 'on either arm';
	$covered{end_mismatch} = 1;
};

subtest 'no_such_arm' => sub {
	plan tests => 2;
	my $g = rigged(hand => [ tile(6, 2) ], opening => [ [ tile(6, 4), 'L' ] ]);
	is refusal($g->play(1, { tile => tile(6, 2), arm => 'Z' })), 'no_such_arm',
		'there is no arm Z';
	is refusal($g->play(1, { tile => tile(6, 2), arm => 'l' })), 'no_such_arm',
		'and arms are not case insensitive';
	$covered{no_such_arm} = 1;
};

subtest 'arm_closed' => sub {
	plan tests => 3;
	# The spinner is down but neither of its sides is covered, so the two
	# perpendicular arms are not open yet. Pagat: "the first and second tiles
	# adjacent to the spinner must be placed against the two sides, then the
	# third and fourth tiles must be placed against the ends."
	my $g = rigged(hand => [ tile(5, 6) ], opening => [ [ tile(5, 5), 'L' ] ]);
	is $g->layout->sides_covered, 0, 'neither side of the spinner is covered';
	is refusal($g->play(1, '6-5@U')), 'arm_closed', 'so the U arm refuses a tile';
	is refusal($g->play(1, '6-5@D')), 'arm_closed', 'and so does D';
	$covered{arm_closed} = 1;
};

subtest 'game_over' => sub {
	plan tests => 2;
	my $g = rigged(hand => [ tile(6, 4) ]);
	$g->resign(1);
	is $g->status, 'finished', 'the game is over';
	is refusal($g->play(1, '6-4@L')), 'game_over', 'and nothing more may be played';
	$covered{game_over} = 1;
};

subtest 'bad_move' => sub {
	plan tests => 5;
	my $g = rigged(hand => [ tile(6, 4) ]);
	is refusal($g->play(1, 'nonsense')), 'bad_move', 'a string that is not a move';
	is refusal($g->play(1, 'P')), 'bad_move', 'a pass is not a move a caller makes';
	is refusal($g->play(1, 'D')), 'bad_move', 'and neither is a draw';
	is refusal($g->play(1, undef)), 'bad_move', 'nothing at all is not a move';
	is refusal($g->play(1, {})), 'bad_move', 'and nor is an empty hashref';
	$covered{bad_move} = 1;
};

subtest 'a legal play is not refused' => sub {
	plan tests => 4;
	my $g = rigged(hand => [ tile(6, 2) ], opening => [ [ tile(6, 4), 'L' ] ]);
	my $out = $g->play(1, '6-2@L');
	isa_ok $out, 'Game::Dominoes::Play', 'a good play';
	is $out->tile->stringify, '6-2', 'it played the tile asked for';
	is $out->arm, 'L', 'on the arm asked for';
	ok !$g->hand(1)->holds(tile(6, 2)), 'and the tile left the hand';
};

subtest 'every flag is reachable, and no flag is unreachable' => sub {
	my $flags = Game::Dominoes::Error->flags;
	plan tests => scalar(@$flags) + 1;

	ok $covered{$_}, "$_ was produced by a real refusal above" for @$flags;

	is_deeply [ sort keys %covered ], [ sort @$flags ],
		'and the subtests above cover exactly the flags that exist';
};
