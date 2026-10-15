package Game::Snake::Bot;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();

our $VERSION = '0.13';

our @LADDER = (1, 2);

my %DESCRIBE = (
	1 => 'greedy: of the safe headings, the one that closes on the food',
	2 => 'flood-fill: greedy, but never into a space smaller than itself while a bigger one is open',
);

my %DELTA = (
	up    => [ 0, -1 ],
	down  => [ 0, 1 ],
	left  => [ -1, 0 ],
	right => [ 1, 0 ],
);

my %SIDES = (
	up    => [ 'left', 'right' ],
	down  => [ 'left', 'right' ],
	left  => [ 'up', 'down' ],
	right => [ 'up', 'down' ],
);

sub levels { return @LADDER }

sub describe {
	my ($class, $level) = @_;
	return $DESCRIBE{ $class->_level($level) };
}

sub _level {
	my ($class, $level) = @_;
	$level = $LADDER[-1] unless defined $level;
	Carp::croak("Game::Snake::Bot: a level is one of @LADDER, not '$level'")
		unless !ref $level && $DESCRIBE{$level};
	return $level;
}

my $scan = sub {
	my ($game) = @_;
	my $cols = $game->cols;
	my $segments = $game->segments;
	my $growing = $game->growing;
	my @blocked;
	for my $i (0 .. $#$segments) {
		my $segment = $segments->[$i];
		next if $i == $#$segments && $i > 0 && !$growing;
		$blocked[ $segment->{y} * $cols + $segment->{x} ] = 1;
	}
	return \@blocked;
};

my $ahead = sub {
	my ($head, $direction) = @_;
	my $delta = $DELTA{$direction};
	return ($head->{x} + $delta->[0], $head->{y} + $delta->[1]);
};

my $fatal = sub {
	my ($game, $blocked, $x, $y) = @_;
	return 1 if $x < 0 || $y < 0 || $x >= $game->cols || $y >= $game->rows;
	return $blocked->[ $y * $game->cols + $x ] ? 1 : 0;
};

my $region = sub {
	my ($game, $blocked, $x0, $y0) = @_;
	my ($cols, $rows) = ($game->cols, $game->rows);
	return (0, []) if $x0 < 0 || $y0 < 0 || $x0 >= $cols || $y0 >= $rows;
	my $start = $y0 * $cols + $x0;
	return (0, []) if $blocked->[$start];
	my @seen;
	$seen[$start] = 1;
	my @queue = ($start);
	my $at = 0;
	while ($at < @queue) {
		my $k = $queue[ $at++ ];
		my $x = $k % $cols;
		my @next;
		push @next, $k - 1 if $x > 0;
		push @next, $k + 1 if $x < $cols - 1;
		push @next, $k - $cols if $k >= $cols;
		push @next, $k + $cols if $k + $cols < $cols * $rows;
		for my $n (@next) {
			next if $seen[$n] || $blocked->[$n];
			$seen[$n] = 1;
			push @queue, $n;
		}
	}
	return (scalar @queue, \@seen);
};

my $closest = sub {
	my ($head, $directions, $food) = @_;
	my (@best, $best);
	for my $direction (@$directions) {
		my ($x, $y) = $ahead->($head, $direction);
		my $distance = abs($food->[0] - $x) + abs($food->[1] - $y);
		if (!defined $best || $distance < $best) {
			$best = $distance;
			@best = ($direction);
		}
		elsif ($distance == $best) {
			push @best, $direction;
		}
	}
	return \@best;
};

my $tie = sub {
	my ($game, $heading, $list) = @_;
	return $heading unless @$list;
	return $heading if grep { $_ eq $heading } @$list;
	return $list->[0] if @$list == 1;
	my $hash = Digest::SHA::sha256($game->seed . 'snake:bot:' . $game->ticks);
	return $list->[ unpack('N', substr($hash, 0, 4)) % @$list ];
};

sub room {
	my ($class, $game, $direction) = @_;
	Carp::croak("Game::Snake::Bot: '" . (defined $direction ? $direction : 'undef')
		. "' is not a direction")
		unless defined $direction && $DELTA{$direction};
	my ($head) = @{ $game->segments };
	my $blocked = $scan->($game);
	my ($room) = $region->($game, $blocked, $ahead->($head, $direction));
	return $room;
}

sub safe {
	my ($class, $game) = @_;
	return () if $game->status eq 'finished';
	my ($head) = @{ $game->segments };
	my $heading = $game->heading;
	my $blocked = $scan->($game);
	return grep { !$fatal->($game, $blocked, $ahead->($head, $_)) }
		$heading, @{ $SIDES{$heading} };
}

sub choose {
	my ($class, $game, %with) = @_;
	my $level = $class->_level($with{level});

	return undef if $game->status eq 'finished';

	my ($head) = @{ $game->segments };
	my $heading = $game->heading;
	my $blocked = $scan->($game);

	my @safe = grep { !$fatal->($game, $blocked, $ahead->($head, $_)) }
		$heading, @{ $SIDES{$heading} };
	return $heading unless @safe;

	my $food = $game->food;

	if ($level == 1) {
		return $tie->($game, $heading, \@safe) unless $food;
		return $tie->($game, $heading, $closest->($head, \@safe, $food));
	}

	my $length = $game->length;
	my (%room, $most);
	for my $direction (@safe) {
		my ($count) = $region->($game, $blocked, $ahead->($head, $direction));
		$room{$direction} = $count;
		$most = $count if !defined $most || $count > $most;
	}
	my @big = grep { $room{$_} >= $length } @safe;
	@big = grep { $room{$_} == $most } @safe unless @big;
	return $tie->($game, $heading, \@big) if @big == 1 || !$food;
	return $tie->($game, $heading, $closest->($head, \@big, $food));
}

1;

__END__

=head1 NAME

Game::Snake::Bot - a snake steered once a tick, at one of three levels

=head1 VERSION

Version 0.13

=head1 SYNOPSIS

    use Game::Snake;
    use Game::Snake::Bot;

    my $game = Game::Snake->new(seed => $seed);

    while ($game->status ne 'finished') {
        my $direction = Game::Snake::Bot->choose($game, level => 2);
        $game->turn($direction) if $direction ne $game->heading;
        $game->tick;
    }

=head1 DESCRIPTION

Asked once a tick, this answers the heading the snake should take next. Two
levels share one look at the board and differ in what they do with it:

=over 4

=item 1 greedy

Of the safe headings, the one that closes on the food. A heading is safe when
the next cell will not kill it, and that is all it looks at.

=item 2 flood-fill

Greedy, but it counts the free cells reachable behind each safe heading and
never takes a space smaller than its own length while a bigger one is open.

=back

Two levels, not three, and both were measured. A reflex level that merely
avoids the next fatal cell was tried first: alone on an empty board it circles
the edge for ever and never eats. A third level that looked one step ahead and
kept a way back to its tail was tried after: it scored a little above
flood-fill on a small board and below it on the full 40 by 28 one. A level
that is better everywhere needs a search over several ticks, which this
module does not do.

A cell is fatal when it is off the board or on the snake, except the tail
when the tail is about to leave it. A tie is broken by the heading the snake
already has, then by a hash of the game's seed and tick, so the same seed
plays the same game twice and nothing here calls C<rand>.

The bot is a set of class methods and keeps nothing between ticks.

=head1 METHODS

=head2 choose

    my $direction = Game::Snake::Bot->choose($game, level => 2);

The heading to take, one of C<up>, C<down>, C<left> and C<right>. The level
is 1 or 2 and defaults to 2. Returns the heading the snake already has
when nothing is safe, and undefined once the game has finished. A level that
is not on the ladder is a programmer error and dies.

=head2 safe

    my @safe = Game::Snake::Bot->safe($game);

The headings the snake may take this tick without dying: straight on and
the two sides, less the fatal ones.

=head2 room

    my $cells = Game::Snake::Bot->room($game, 'up');

How many free cells the snake could reach after stepping that way, 0 when
the step itself is fatal.

=head2 levels

The ladder, C<(1, 2)>.

=head2 describe

    print Game::Snake::Bot->describe(3);

One line on what a level does.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
