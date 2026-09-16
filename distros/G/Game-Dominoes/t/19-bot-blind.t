#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Boneyard;
use Game::Dominoes::Hand;
use Game::Dominoes::Set qw(tiles);
use Game::Dominoes::Tile;

# THE ANTI-CHEAT GATE.
#
# In a perfect information game a bot that reads too much state is harmless.
# Here it is the difference between an opponent and a fraud, and no ordinary
# test catches it: a cheating bot plays legal moves, wins a believable share of
# its games, and passes every other file in this suite.
#
# The gate is the one thing that does catch it:
#
#   Build a position. Construct many games that are IDENTICAL in one seat's
#   view and DIFFERENT in the hidden tiles. The play choose() returns must be
#   the same in all of them.
#
# A bot that consults a hidden hand returns a different play when that hand
# changes and fails here immediately.
#
# This is the mirror of the site's t/33-gate-view-leak.t. That one checks a
# view does not CARRY what it should not; this one checks the bot does not USE
# what it was not given. They catch different bugs and both are needed.
#
# THIS TEST IS NEVER SKIPPED AND NEVER MARKED TODO.

plan tests => 5;

sub tile { Game::Dominoes::Tile->of(@_) }

sub name { my ($m) = @_; return $m ? $m->{tile}->stringify . '@' . $m->{arm} : '-' }

# Build a position where seat 1 holds exactly @own, the table holds @table,
# and the remaining tiles are shared out among the other seats and the
# boneyard according to $split, which is a permutation index.
sub position {
	my (%args) = @_;
	my $players = $args{players} || 2;

	my $g = Game::Dominoes->new(
		seed => 'a' x 32,
		players => $players,
		hands => { 1 => Game::Dominoes::Hand->new(tiles => [ @{ $args{own} } ]) },
	);

	$g->layout->place($_->[0], $_->[1]) for @{ $args{table} || [] };

	my %used = map { $_->id => 1 } @{ $args{own} }, map { $_->[0] } @{ $args{table} || [] };
	my @rest = grep { !$used{ $_->id } } @{ tiles() };

	# A different rotation of the unseen tiles for each variant: same counts,
	# same view, completely different hidden state.
	my $by = $args{rotate} || 0;
	@rest = (@rest[ $by .. $#rest ], @rest[ 0 .. $by - 1 ]) if $by;

	for my $seat (2 .. $players) {
		my @take = splice @rest, 0, $args{others};
		$g->hands->{$seat} = Game::Dominoes::Hand->new(tiles => \@take);
	}
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => [@rest]));
	$g->turn(1);
	return $g;
}

subtest 'the fixture really does vary the hidden tiles' => sub {
	plan tests => 3;

	# A gate that silently built identical positions would pass for the wrong
	# reason and prove nothing, so prove the fixture first.
	my @own = (tile(6, 4), tile(6, 1), tile(3, 3));
	my $a = position(own => \@own, others => 5, rotate => 0);
	my $b = position(own => \@own, others => 5, rotate => 7);

	isnt $a->hand(2)->stringify, $b->hand(2)->stringify,
		'seat 2 holds different tiles in the two positions';
	is $a->hand(1)->stringify, $b->hand(1)->stringify,
		'while seat 1 holds the same';
	is $a->boneyard_count, $b->boneyard_count, 'and the boneyard is the same size';
};

subtest 'the two positions are the same to seat 1' => sub {
	plan tests => 6;

	my @own = (tile(6, 4), tile(6, 1), tile(3, 3));
	my $a = position(own => \@own, others => 5, rotate => 0)->view(1);
	my $b = position(own => \@own, others => 5, rotate => 7)->view(1);

	is_deeply $a->{counts}, $b->{counts}, 'the hand sizes match';
	is $a->{boneyard}, $b->{boneyard}, 'the boneyard count matches';
	is_deeply $a->{ends}, $b->{ends}, 'the open ends match';
	is_deeply $a->{scores}, $b->{scores}, 'the scores match';
	is_deeply $a->{deductions}, $b->{deductions}, 'the deductions match';
	is join(' ', map { $_->stringify } @{ $a->{hand} }),
		join(' ', map { $_->stringify } @{ $b->{hand} }),
		'and seat 1 sees the same tiles in its own hand';
};

subtest 'a view carries nothing it should not' => sub {
	plan tests => 4;

	my $g = position(own => [ tile(6, 4), tile(6, 1) ], others => 5);
	my $view = $g->view(1);

	# Whatever else changes, these three must never appear.
	my @flat = %$view;
	is scalar(grep { ref $_ eq 'Game::Dominoes::Boneyard' } @flat), 0,
		'no boneyard object, so no way to peek at its tiles';
	ok !exists $view->{seed}, 'no seed while the game is running';
	ok !exists $view->{hands}, 'no map of everybody hands';

	my %own = map { $_->id => 1 } @{ $view->{hand} };
	my $leaked = 0;
	for my $tile (@{ $g->hand(2)->tiles }) {
		$leaked++ if $own{ $tile->id };
	}
	is $leaked, 0, 'and none of seat 2 tiles are in what seat 1 was handed';
};

subtest 'THE GATE: identical view, varied hidden tiles, identical play' => sub {
	plan tests => 2;

	# Twelve positions, each with the hidden tiles rotated differently, at
	# each of three levels and two seat counts. If the bot reads anything it
	# was not given, one of these disagrees.
	my @positions = (
		[ tile(6, 4), tile(6, 1), tile(3, 3) ],
		[ tile(5, 5), tile(5, 2), tile(0, 0) ],
		[ tile(6, 6), tile(4, 1), tile(3, 2), tile(1, 0) ],
	);

	my ($checked, $disagreed) = (0, 0);
	my @report;

	for my $own (@positions) {
		for my $players (2, 3) {
			for my $level (1, 2, 3) {
				my %seen;
				for my $rotate (0, 3, 7, 11) {
					my $g = position(
						own => $own, others => 4,
						players => $players, rotate => $rotate,
					);
					my $bot = Game::Dominoes::Bot->new(level => $level, seed => 42);
					$seen{ name($bot->choose($g, 1)) }++;
				}
				$checked++;
				next if keys %seen == 1;
				$disagreed++;
				push @report, "level $level, $players seats: "
					. join(' vs ', sort keys %seen);
			}
		}
	}

	cmp_ok $checked, '>', 15, 'the gate ran over enough positions to mean something';
	is $disagreed, 0, 'the bot chose identically every time'
		or diag("the bot read hidden state:\n  " . join("\n  ", @report));
};

subtest 'THE GATE proves something: a peeking bot fails it' => sub {
	plan tests => 2;

	# A gate nobody has seen fail is a gate nobody knows works. This builds a
	# deliberately cheating bot, one that looks at another seat's actual
	# tiles, and shows the gate catches it.
	# A standalone package rather than a subclass. Object::Proto::Sugar's new
	# blesses into the class that declared the attributes and not into the
	# invocant, so `our @ISA = ('Game::Dominoes::Bot')` hands back a plain
	# parent object and the override never runs. That silently turned this
	# test green for the wrong reason on its first draft.
	{
		package Cheating::Bot;
		sub new { my ($class, %o) = @_; return bless {%o}, $class }
		sub choose {
			my ($self, $game, $seat) = @_;
			my $view = $game->view($seat);
			my $hand = Game::Dominoes::Hand->new(tiles => [ @{ $view->{hand} } ]);
			my $all = Game::Dominoes::Rules::candidates($view->{layout}, $hand);
			return $all->[0] unless @$all > 1;

			# The cheat, and it is the realistic shape of one: look at the
			# tiles an opponent actually holds and let them steer the choice.
			# Nothing about this is visible from outside. It plays legal
			# moves, it wins a believable share of its games, and every other
			# file in this suite passes it.
			my $other = $game->hand($seat == 1 ? 2 : 1) or return $all->[0];
			my $peek = 0;
			$peek += $_->id for @{ $other->tiles };
			return $all->[ $peek % scalar(@$all) ];
		}
	}

	my @own = (tile(6, 4), tile(6, 1), tile(3, 3));
	my (%honest, %cheat);
	for my $rotate (0, 2, 3, 5, 7, 9, 11, 13) {
		my $g = position(own => \@own, others => 5, rotate => $rotate);
		$honest{ name(Game::Dominoes::Bot->new(level => 1, seed => 42)->choose($g, 1)) }++;
		$cheat{ name(Cheating::Bot->new(level => 1, seed => 42)->choose($g, 1)) }++;
	}

	is scalar(keys %honest), 1, 'the real bot gives one answer across all eight worlds';
	cmp_ok scalar(keys %cheat), '>', 1,
		'the cheating bot gives more than one, which is exactly what the gate catches';
};
