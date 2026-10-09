#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Board;
use Game::Merrills::Rules;
use Game::Merrills::Test::Position qw/stream/;

# THE NUMBERS ARE WORKED OUT BY HAND, NOT PRINTED BY THE CODE AND PASTED BACK.
#
#   ply 1          24    one man on any of 24 points
#   ply 2         552    24 x 23
#   ply 3      12,144    x 22
#   ply 4     255,024    x 21
#
# No mill can close before white's third man, which is ply 5, so until then a
# ply is just "one fewer empty point". Ply 5 is 255,024 x 20 + 40,320 and is
# in xt/perft-deep.t with its own working.
#
# Ply 4 is counted here without being walked: it is the sum of the number of
# legal moves at each of the 12,144 positions three plies in.

my @SIDE = qw/white black/;

sub opening {
	return Game::Merrills::Rules::position(Game::Merrills::Board->new);
}

sub count {
	my ($position, $ply, $depth) = @_;
	my $moves = Game::Merrills::Rules::generate($position, $SIDE[ $ply % 2 ]);
	return scalar @{$moves} if $depth == 1;
	my $total = 0;
	for my $move (@{$moves}) {
		Game::Merrills::Rules::apply($position, $SIDE[ $ply % 2 ], $move);
		$total += count($position, $ply + 1, $depth - 1);
		Game::Merrills::Rules::unapply($position, $SIDE[ $ply % 2 ], $move);
	}
	return $total;
}

subtest 'the first four plies' => sub {
	my $position = opening();
	is(count($position, 0, 1), 24, 'ply 1: 24');
	is(count($position, 0, 2), 552, 'ply 2: 552');
	is(count($position, 0, 3), 12144, 'ply 3: 12,144');
	is(count($position, 0, 4), 255024, 'ply 4: 255,024');
	is_deeply($position, opening(), 'and the walk left the opening as it found it');
};

# The twin never takes a move back. It copies the position, plays the move on
# the copy and walks on from there, so a fault in unapply cannot hide in it.
sub twin {
	my ($position, $ply, $depth) = @_;
	my $moves = Game::Merrills::Rules::generate($position, $SIDE[ $ply % 2 ]);
	return scalar @{$moves} if $depth == 1;
	my $total = 0;
	for my $move (@{$moves}) {
		my $copy = [ @{$position} ];
		Game::Merrills::Rules::apply($copy, $SIDE[ $ply % 2 ], $move);
		$total += twin($copy, $ply + 1, $depth - 1);
	}
	return $total;
}

subtest 'taking moves back agrees with never taking them back' => sub {
	is(twin(opening(), 0, 3), 12144, 'the copying walk counts ply 3 the same');

	my $next = stream(2020);
	my ($positions, $wrong, $phases) = (0, 0, {});
	my $tries = 0;
	while ($positions < 300 && $tries++ < 3000) {
		my $game = Game::Merrills->new;
		my $stop = 14 + $next->(60);
		while ($game->status eq 'active' && $game->ply < $stop) {
			my $legal = $game->legal_moves;
			$game->move($legal->[ $next->(scalar @{$legal}) ]);
		}
		next unless $game->status eq 'active';
		$positions++;
		$phases->{ $game->phase }++;

		my $position = Game::Merrills::Rules::position($game->board);
		my $before = join ',', @{$position};
		my $ply = $game->turn eq 'white' ? 0 : 1;
		$wrong++ unless count($position, $ply, 2) == twin($position, $ply, 2);
		$wrong++ unless join(',', @{$position}) eq $before;
	}
	is($positions, 300, 'three hundred positions found');
	is($wrong, 0, 'two plies deep from 300 positions, the two walks agree and leave no mark');
	cmp_ok($phases->{$_} || 0, '>', 20, "$_: " . ($phases->{$_} || 0) . ' of the 300')
		for qw/placing moving flying/;
};

done_testing;
