package Game::Snake::Test::Steer;

use strict;
use warnings;

our $VERSION = '0.12';

# Two ways to steer a Game::Snake from a test without a bot (the bot is phase
# 02's). `greedy` heads for the food along the shorter axis, refusing any
# cell that would kill it, and is enough to drive a game to a real ending on
# a small board. `cycle6` follows one Hamiltonian cycle round a 6x6 board, so
# a snake steered by it eats everything and ends the game `full`.

my %DELTA = (up => [0, -1], down => [0, 1], left => [-1, 0], right => [1, 0]);
my %OPPOSITE = (up => 'down', down => 'up', left => 'right', right => 'left');

sub fatal {
	my ($game, $x, $y) = @_;
	return 1 if $x < 0 || $y < 0 || $x >= $game->cols || $y >= $game->rows;
	my $what = $game->at($x, $y);
	return 0 unless defined $what;
	return 0 if $what eq 'food';
	return 0 if $what eq 'tail' && $game->length > 1;
	return 1;
}

sub greedy {
	my ($class, $game) = @_;
	my ($head) = @{ $game->segments };
	my $food = $game->food or return undef;
	my $heading = $game->heading;

	my @want;
	my $dx = $food->[0] - $head->{x};
	my $dy = $food->[1] - $head->{y};
	if (abs $dx >= abs $dy) {
		push @want, $dx < 0 ? 'left' : 'right' if $dx;
		push @want, $dy < 0 ? 'up' : 'down' if $dy;
	}
	else {
		push @want, $dy < 0 ? 'up' : 'down' if $dy;
		push @want, $dx < 0 ? 'left' : 'right' if $dx;
	}
	push @want, grep { my $d = $_; !grep { $_ eq $d } @want } qw/ up down left right /;

	for my $direction (@want) {
		next if $direction eq $OPPOSITE{$heading};
		my ($ddx, $ddy) = @{ $DELTA{$direction} };
		next if fatal($game, $head->{x} + $ddx, $head->{y} + $ddy);
		return $direction;
	}
	return $heading;
}

my @CYCLE6;
{
	push @CYCLE6, [ $_, 0 ] for 0 .. 5;
	for my $row (1 .. 4) {
		my @cols = $row % 2 ? reverse(1 .. 5) : (1 .. 5);
		push @CYCLE6, [ $_, $row ] for @cols;
	}
	push @CYCLE6, [ $_, 5 ] for reverse 0 .. 5;
	push @CYCLE6, [ 0, $_ ] for reverse 1 .. 4;
}

sub cycle6 {
	my ($class, $game) = @_;
	my ($head) = @{ $game->segments };
	for my $i (0 .. $#CYCLE6) {
		next unless $CYCLE6[$i][0] == $head->{x} && $CYCLE6[$i][1] == $head->{y};
		my $next = $CYCLE6[ ($i + 1) % @CYCLE6 ];
		my ($dx, $dy) = ($next->[0] - $head->{x}, $next->[1] - $head->{y});
		for my $direction (keys %DELTA) {
			return $direction
				if $DELTA{$direction}[0] == $dx && $DELTA{$direction}[1] == $dy;
		}
	}
	die "the head is off the cycle at $head->{x},$head->{y}";
}

sub cycle6_cells { return [ map { [@$_] } @CYCLE6 ] }

sub play {
	my ($class, $game, $steer, $max) = @_;
	my @steps;
	while ($game->status ne 'finished' && @steps < $max) {
		my $direction = $class->$steer($game);
		$game->turn($direction) if defined $direction && $direction ne $game->heading;
		push @steps, $game->tick;
	}
	return \@steps;
}

1;
