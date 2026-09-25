package Game::Mahjong::Result;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use constant BASE   => 8;
use constant SEATS  => 4;
use constant HANDS  => 16;
use constant ROUNDS => 4;

sub settle {
	my (%o) = @_;
	my @deltas = (0) x SEATS;
	my $by = $o{by} // '';
	return \@deltas if $by eq 'exhausted';

	my $winner = $o{winner};
	die 'Game::Mahjong::Result: the winner is a seat 0 to 3'
		unless defined $winner && $winner =~ /\A[0-3]\z/;
	my $points = $o{points};
	die 'Game::Mahjong::Result: points are a whole number'
		unless defined $points && $points =~ /\A\d+\z/;

	if ($by eq 'self') {
		for my $seat (0 .. SEATS - 1) {
			next if $seat == $winner;
			$deltas[$seat] -= BASE + $points;
			$deltas[$winner] += BASE + $points;
		}
		return \@deltas;
	}
	if ($by eq 'discard' || $by eq 'rob') {
		my $from = $o{from};
		die 'Game::Mahjong::Result: a win by discard names the discarder'
			unless defined $from && $from =~ /\A[0-3]\z/ && $from != $winner;
		for my $seat (0 .. SEATS - 1) {
			next if $seat == $winner;
			my $gives = $seat == $from ? BASE + $points : BASE;
			$deltas[$seat] -= $gives;
			$deltas[$winner] += $gives;
		}
		return \@deltas;
	}
	die "Game::Mahjong::Result: no such way to win '$by'";
}

sub places {
	my ($totals) = @_;
	my @seats = sort { $totals->[$b] <=> $totals->[$a] || $a <=> $b } 0 .. $#$totals;
	my (@places, $place, $last);
	for my $i (0 .. $#seats) {
		my $seat = $seats[$i];
		if (!defined $last || $totals->[$seat] != $last) {
			$place = $i + 1;
			$last = $totals->[$seat];
		}
		$places[$seat] = $place;
	}
	return \@places;
}

sub winner {
	my ($totals) = @_;
	my $places = places($totals);
	my @first = grep { $places->[$_] == 1 } 0 .. $#$places;
	return @first == 1 ? $first[0] : undef;
}

sub finished {
	my ($hands_played) = @_;
	return $hands_played >= HANDS ? 1 : 0;
}

1;

__END__

=head1 NAME

Game::Mahjong::Result - the settlement of a hand, and the standings of a game

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $deltas = Game::Mahjong::Result::settle(winner => 2, by => 'discard', from => 0, points => 16);
    # [ -24, -8, 40, -8 ]: the discarder gives 8 + 16, the other two give 8 each

    Game::Mahjong::Result::places([ 40, -10, 40, -70 ]);   # [ 1, 3, 1, 4 ]
    Game::Mahjong::Result::winner([ 40, -10, 40, -70 ]);   # undef: a shared first

=head1 DESCRIPTION

The rulebook's settlement (3.9.1.3), as signed deltas that sum to zero:

    self-drawn   every other seat gives BASE + points
    discard      the discarder gives BASE + points, the other two give BASE
    exhausted    nobody moves

C<BASE> is 8 (3.9.1.2, "Non-winning players must pay 8 points"), and
C<points> are the hand's including its flowers. Robbing the kong is a win by
discard whose discarder is the seat that promoted the kong. Totals may go
below zero; nothing clamps them. The words are "gives" and "loses".

=head2 The standings

Competition ranking of the totals, highest first: equal totals share a
place and the next place is skipped. The winner is the sole first place, or
undef when first is shared. A game is sixteen hands, four rounds of four
(3.4.3, 3.4.4), and the deal passes every hand (3.4.8), so C<finished> is a
count.

=head1 FUNCTIONS

=head2 settle

    my $deltas = settle(winner => $seat, by => 'self' | 'discard' | 'rob' | 'exhausted',
                        from => $seat, points => $n);

Four signed deltas indexed by seat. Dies on a bad seat, a discard win with
no discarder, or a way to win it does not know.

=head2 places

Places by seat, 1 the highest.

=head2 winner

The sole first place, or undef.

=head2 finished

Whether the hands played reach C<HANDS>.

=head2 BASE, SEATS, HANDS, ROUNDS

8, 4, 16, 4.

=head1 SEE ALSO

L<Game::Mahjong::Score>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
