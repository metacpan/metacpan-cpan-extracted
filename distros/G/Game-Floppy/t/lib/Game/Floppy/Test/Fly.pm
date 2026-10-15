package Game::Floppy::Test::Fly;

use strict;
use warnings;

our $VERSION = '0.10';

# Scripted flappers for the engine's tests, so the bot (phase 02) is not
# needed here. Each is a code reference called with the game before a tick
# and returning whether to flap. `play` drives a game with one of them.

sub never  { return sub { 0 } }
sub always { return sub { 1 } }

sub every {
	my ($class, $n) = @_;
	return sub { my ($game) = @_; return ($game->ticks + 1) % $n == 0 ? 1 : 0 };
}

sub hold {
	my ($class, $y) = @_;
	return sub { my ($game) = @_; return $game->bird->{y} > $y ? 1 : 0 };
}

sub advance {
	my ($class, $game, $n) = @_;
	my $fly = $class->every(10);
	for (1 .. $n) {
		$game->flap if $fly->($game);
		$game->tick;
	}
	return $game;
}

sub play {
	my ($class, $game, $flyer, $max) = @_;
	my @steps;
	while ($game->status ne 'finished' && @steps < $max) {
		$game->flap if $flyer->($game);
		push @steps, $game->tick;
	}
	return \@steps;
}

1;
