package Game::Terminal::Kit::Steer;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.05';

my %WAY = (
	up    => [ 0, -1 ],
	down  => [ 0, 1 ],
	left  => [ -1, 0 ],
	right => [ 1, 0 ],
);

sub way {
	my ($key) = @_;
	return () unless defined $key && $WAY{$key};
	return @{ $WAY{$key} };
}

sub ring {
	my ($count, $at, $delta, $skip) = @_;
	return $at unless $count && $delta;
	my $step = $delta > 0 ? 1 : -1;
	my $next = ($at + $delta) % $count;
	for (1 .. $count) {
		return $next unless $skip && $skip->($next);
		$next = ($next + $step) % $count;
	}
	return $at;
}

sub clamp {
	my ($count, $at, $delta, $skip) = @_;
	return $at unless $count && $delta;
	my $step = $delta > 0 ? 1 : -1;
	my $next = $at + $delta;
	$next = 0 if $next < 0;
	$next = $count - 1 if $next > $count - 1;
	while ($next >= 0 && $next < $count) {
		return $next unless $skip && $skip->($next);
		$next += $step;
	}
	return $at;
}

sub nearest {
	my ($points, $at, $dx, $dy, %option) = @_;
	return undef unless $dx || $dy;
	my $from = $points->[$at] or return undef;
	my $skip = $option{skip};
	my ($best, $best_cost, $best_across);
	for my $index (0 .. $#{$points}) {
		next if $index == $at;
		next if $skip && $skip->($index);
		my $x = $points->[$index][0] - $from->[0];
		my $y = $points->[$index][1] - $from->[1];
		my $along = $x * $dx + $y * $dy;
		my $across = abs($x * $dy - $y * $dx);
		next if $along <= 0;
		next if $option{cone} && $across > $along;
		my $cost = $along + 2 * $across;
		next if defined $best
			&& ($cost > $best_cost || ($cost == $best_cost && $across >= $best_across));
		($best, $best_cost, $best_across) = ($index, $cost, $across);
	}
	return $best;
}

sub axis {
	my ($points, $at, $dx, $dy) = @_;
	return $at unless $dx || $dy;
	my ($first, $second) = $dx ? (0, 1) : (1, 0);
	my @order = sort {
		$points->[$a][$first] <=> $points->[$b][$first]
			|| $points->[$a][$second] <=> $points->[$b][$second]
			|| $a <=> $b
	} 0 .. $#{$points};
	my ($where) = grep { $order[$_] == $at } 0 .. $#order;
	return $at unless defined $where;
	$where += ($dx || $dy) > 0 ? 1 : -1;
	return $where >= 0 && $where <= $#order ? $order[$where] : $at;
}

sub rest {
	my ($items, $prefer) = @_;
	my @open = grep { !(ref $items->[$_] eq 'HASH' && $items->[$_]{skip}) } 0 .. $#{$items};
	return 0 unless @open;
	if ($prefer) {
		for my $index (@open) {
			return $index if $prefer->($items->[$index], $index);
		}
	}
	return $open[0];
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Steer - move a cursor the way the key points

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Steer;

    # a row or a list: an index and a step
    $at = Game::Terminal::Kit::Steer::ring(scalar @drawn, $at, +1);

    # a board: where each thing is on the screen, and a direction
    my @points = map { [ $_->column, $_->row ] } @drawn;
    my $next = Game::Terminal::Kit::Steer::nearest(
        \@points, $at, Game::Terminal::Kit::Steer::way($key),
    );
    $at = $next if defined $next;

=head1 DESCRIPTION

A cursor has to go where the arrow key points on the screen. It stops doing
so the moment it walks one list while the screen draws another: a hand held
in the order it was dealt and drawn sorted into suits, a set of legal moves
in the order the rules found them and drawn where they are on the board.
Every item is still reachable, so nothing fails; right has just stopped
meaning right.

Every function here therefore takes B<what was drawn, in the order or at the
place it was drawn>. Build the list the cursor walks from the same function
the screen is drawn from, and hand that list over.

=head2 Indexes and points

For a row or a column of things, the cursor is an index into the drawn list
and L</ring> or L</clamp> moves it.

For things scattered over a board, each has a point, C<[$x, $y]>, in columns
and rows counted from the top left as the screen counts them, so down is a
greater C<y>. The cursor is still an index, into the list of points, and
L</nearest> or L</axis> moves it. A direction is two numbers, the change in
C<x> and in C<y>; L</way> gives them for an arrow key, and a game with
diagonals gives its own.

=head1 FUNCTIONS

None is exported.

=head2 ring

    $at = Game::Terminal::Kit::Steer::ring($count, $at, $delta, $skip);

The index C<$delta> on from C<$at> among C<$count>, going round at the ends.
C<$skip>, when given, is called with an index and returns true for one the
cursor may not rest on; it is stepped over in the direction of travel. When
every index is skipped the cursor stays where it is.

=head2 clamp

    $at = Game::Terminal::Kit::Steer::clamp($count, $at, $delta, $skip);

The same, stopping at the ends. A cursor that would have to pass the end to
find somewhere to rest stays where it is.

=head2 nearest

    my $next = Game::Terminal::Kit::Steer::nearest(\@points, $at, $dx, $dy, %option);

The index of the point that is nearest in the direction given, or undef when
nothing lies that way, in which case the cursor should stay. Nearest is the
least distance along the direction plus twice the distance across it, so a
thing straight ahead is preferred to a closer thing off to one side; between
two that cost the same, the one less far across wins, and after that the one
drawn first.

The options are C<cone>, which when true leaves out a point further across
than it is along, so that right never picks something that is mostly up; and
C<skip>, as for L</ring>.

=head2 axis

    $at = Game::Terminal::Kit::Steer::axis(\@points, $at, $dx, $dy);

For a few things on a track: the points are put in order along the axis of
the direction, left to right or top to bottom, and the cursor goes to the
next or the one before. It stops at the ends.

=head2 rest

    my $at = Game::Terminal::Kit::Steer::rest(\@items, sub { $_[0]{loose} });

Where a cursor should start: the first item the code reference accepts, else
the first at all. It is called with the item and its index. An item that is
a hash reference with a true C<skip> is never chosen. A cursor that starts on
the item the player usually means saves a key every turn.

=head2 way

    my ($dx, $dy) = Game::Terminal::Kit::Steer::way('left');    # (-1, 0)

The direction of C<up>, C<down>, C<left> or C<right>; an empty list for any
other key.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Keys>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
