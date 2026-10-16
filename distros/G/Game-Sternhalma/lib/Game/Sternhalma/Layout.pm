package Game::Sternhalma::Layout;

use 5.014;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(seat_counts points home_of pieces_ok why_not);

# W's layouts. Points are 0 to 5 clockwise from the top tip; seat order is
# turn order, which is clockwise too. t/24-layout.t holds this table to the
# engine's own.
my %POINTS = (
    1 => [0],
    2 => [0, 3],
    3 => [0, 2, 4],
    4 => [0, 1, 3, 4],
    6 => [0, 1, 2, 3, 4, 5],
);

sub seat_counts { (2, 3, 4, 6) }

sub points {
    my ($seats) = @_;
    my $p = defined $seats ? $POINTS{$seats} : undef;
    return $p ? @$p : ();
}

sub home_of {
    my ($seats, $seat) = @_;
    my @p = points($seats);
    return undef unless defined $seat && $seat =~ /\A[0-9]+\z/ && $seat < @p;
    return ($p[$seat] + 3) % 6;
}

sub pieces_ok {
    my ($seats, $pieces) = @_;
    return defined why_not($seats, $pieces) ? 0 : 1;
}

# Why a game of that many seats and pieces cannot be, or undef when it can.
# One seat is a crossing alone, which a game is not; it is built only on
# request (Game::Sternhalma's `solo`).
sub why_not {
    my ($seats, $pieces, $solo) = @_;
    return 'the seat count must be a number' unless defined $seats && $seats =~ /\A[0-9]+\z/;
    return 'the piece count must be a number' unless defined $pieces && $pieces =~ /\A[0-9]+\z/;
    return 'five cannot play: one seat would have nobody opposite' if $seats == 5;
    return 'one seat is a crossing alone, not a game' if $seats == 1 && !$solo;
    return "sternhalma is for 2, 3, 4 or 6 seats, not $seats" unless $POINTS{$seats};
    return "a seat has 10 pieces, or 15, not $pieces" unless $pieces == 10 || $pieces == 15;
    return "fifteen pieces cannot sit at $seats seats: neighbouring points would share a hole"
        if $pieces == 15 && $seats > 3;
    return undef;
}

1;

__END__

=head1 NAME

Game::Sternhalma::Layout - which points of the star each seat count uses

=head1 SYNOPSIS

    use Game::Sternhalma::Layout qw(points home_of why_not);

    my @points = points(4);                   # 0, 1, 3, 4
    my $home   = home_of(4, 1);               # 4
    my $why    = why_not(4, 15);              # neighbouring points would share a hole

=head1 DESCRIPTION

The six points of the star are numbered 0 to 5 clockwise from the top. Two
seats start at the top and the bottom; three at every other point, racing into
the three empty ones; four at two opposite pairs side by side, leaving the
other two empty; six everywhere. A seat's home is the point opposite its
start. Seats take turns in seat order, which is clockwise.

Ten pieces a seat, or fifteen for two or three seats: a fifteen-piece start
takes in the five holes of the hexagon in front of the point, and two
neighbouring points would share one of them. Five cannot play.

=head1 FUNCTIONS

=head2 seat_counts

2, 3, 4 and 6.

=head2 points

    points($seats)

The point each seat starts at, in seat order.

=head2 home_of

    home_of($seats, $seat)

The point a seat is racing to.

=head2 pieces_ok

    pieces_ok($seats, $pieces)

True when a game of that many seats can have that many pieces each.

=head2 why_not

    why_not($seats, $pieces)

Why there can be no such game, or C<undef> when there can.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
