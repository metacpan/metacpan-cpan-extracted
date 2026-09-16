#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Bot;

# THE TEST THAT PROVES THE EVALUATION IS NOT DISC COUNT.
#
# Games magazine, November 1982, issue 33, page 46, quoted by Wikipedia:
#
#     Although the goal is to finish with the most pieces of your color up, the
#     best strategy, paradoxically, is usually to limit your opponent's options
#     by flipping over as FEW of his discs as possible during the first
#     two-thirds of the game.
#
# A bot that simply grabbed the most discs would be beatable by rote, and the
# position below is the cheapest demonstration: one move takes a corner and
# turns one disc, another turns four. The greedy answer is the wrong one.
#
# Parentheses on every Test::More call whose first argument is a Class->method
# call: without them it parses as indirect object syntax.

my $B = 'Game::Reversi::Board';

sub sq { return $B->square_of(split //, $_[0]) }

# Derived by hand. The Othello centre, so the opening is over and the bot
# searches rather than drawing from its seed; a corner at a8 worth exactly one
# disc; and a fat move at d3 worth four.
sub corner_or_greed {
	my $board = $B->empty;
	$board->[ sq($_) ] = 'b' for qw(e4 d5);      # the centre, so phase is 'play'
	$board->[ sq($_) ] = 'w' for qw(d4 e5);
	$board->[ sq('b8') ] = 'w';                  # a8 outflanks b8 back to c8
	$board->[ sq('c8') ] = 'b';
	$board->[ sq($_) ] = 'w' for qw(e3 f3 g3);   # d3 outflanks three, plus d4
	$board->[ sq('h3') ] = 'b';
	return $board;
}

subtest 'the fixture offers exactly the choice it claims to' => sub {
	my $game = Game::Reversi->from_board(corner_or_greed(), turn => 'b');

	is($game->phase, 'play', 'the opening is over, so the bot will search');
	is($game->turn, 'b', 'and it is Black to move');

	my %flips = map { $B->name_of($_->square) => $_->turned }
	            @{ $game->legal('b') };

	is($flips{a8}, 1, 'the corner turns one disc');
	is($flips{d3}, 4, 'and the greedy move turns four');
	cmp_ok($flips{d3}, '>', $flips{a8},
		'so a bot counting discs would take d3 and not the corner');

	# Nothing else on the board turns more than the corner does, so the choice
	# really is between those two and not a third thing.
	my ($most) = sort { $b <=> $a } values %flips;
	is($most, 4, 'and d3 is the greediest move there is here');
	done_testing();
};

subtest 'the bot takes the corner, at every level that searches' => sub {
	for my $level (Game::Reversi::Bot->levels) {
		my $game = Game::Reversi->from_board(corner_or_greed(), turn => 'b');
		my $bot = Game::Reversi::Bot->new(level => $level, seed => 'corner');
		my $move = $bot->choose($game, 'b');

		ok($move, "level $level chose something");
		is($B->name_of($move->square), 'a8',
			"level $level takes the corner rather than the four discs");
	}
	done_testing();
};

subtest 'a corner can never be turned, which is why it is worth the most' => sub {
	# NOT FOLKLORE AND NOT A MATTER OF TASTE. Turning a disc needs the played
	# disc and a bounding disc of the same colour on opposite sides of it along
	# some ray. A corner has no square on the far side of ANY ray, because every
	# ray from it leaves the board immediately in at least one of the two
	# directions, so no line through a corner can ever be closed.
	#
	# Asserted directly rather than trusted, over every position a real game
	# passes through: once a disc lands in a corner, it stays that colour to the
	# end of the game.
	my @corners = map { sq($_) } qw(a8 h8 a1 h1);

	my $games = 0;
	my @changed;
	for my $seed (1 .. 6) {
		my $game = Game::Reversi->new(variant => 'historic');
		my %bot = map { $_ => Game::Reversi::Bot->new(level => 2, seed => "$seed$_") }
		          qw(b w);
		my %held;

		while ($game->status eq 'active') {
			my $move = $bot{ $game->turn }->choose($game, $game->turn) or last;
			$game->play($game->turn, $move->square);

			for my $corner (@corners) {
				my $cell = $game->board->[$corner];
				next unless defined $cell;
				if (!exists $held{$corner}) {
					$held{$corner} = $cell;
					next;
				}
				push @changed, $B->name_of($corner) . " in game $seed"
					if $held{$corner} ne $cell;
			}
		}
		$games++;
	}

	is($games, 6, 'six games played out');
	is_deeply(\@changed, [],
		'and no disc in a corner ever changed colour, in any of them');
	done_testing();
};

subtest 'the squares beside a corner are the ones the table punishes' => sub {
	# The other half of the corner rule, and the reason the weight table is not
	# simply "corners are good": playing next to an empty corner is what hands
	# it over. This asserts the shape of the table rather than its numbers,
	# which are ours and not cited.
	my $source = do {
		open my $fh, '<', $INC{'Game/Reversi/Bot.pm'} or die $!;
		local $/; <$fh>;
	};
	my ($block) = $source =~ /my \@WEIGHT = \(\s*(.*?)\);/s;
	ok($block, 'found the weight table');

	my @weight = grep { /\S/ } map { s/\s//gr } split /,/, $block;
	is(scalar @weight, 64, 'it has 64 entries');

	for my $corner (qw(a8 h8 a1 h1)) {
		my $at = sq($corner);
		my ($row, $col) = (int($at / 8), $at % 8);

		# Its three neighbours: along the edge both ways, and the diagonal.
		my @beside;
		for my $dr (-1, 0, 1) {
			for my $dc (-1, 0, 1) {
				next if $dr == 0 && $dc == 0;
				my ($r, $c) = ($row + $dr, $col + $dc);
				next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
				push @beside, $r * 8 + $c;
			}
		}
		is(scalar @beside, 3, "$corner has three neighbours");

		cmp_ok($weight[$at], '>', 0, "$corner is worth something");
		for my $near (@beside) {
			cmp_ok($weight[$near], '<', 0,
				"$corner: the square at " . $B->name_of($near) . ' beside it is a penalty');
		}
	}
	done_testing();
};

done_testing();
