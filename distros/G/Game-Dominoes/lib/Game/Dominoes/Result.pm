package Game::Dominoes::Result;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our @REASONS;

BEGIN { @REASONS = qw/target blocked resign timeout/ }

has places => (
	is => 'ro',
	isa => HashRef,
	default => {}
);

has scores => (
	is => 'ro',
	isa => HashRef,
	default => {}
);

has reason => (
	is => 'ro',
	isa => Str
);

sub BUILD {
	my ($self) = @_;
	if (defined $self->reason) {
		die 'Game::Dominoes::Result: unknown reason ' . $self->reason
			unless grep { $_ eq $self->reason } @REASONS;
	}
	return $self;
}

sub reasons {
	return [@REASONS];
}

sub winners {
	my ($self) = @_;
	my $places = $self->places;
	return [ sort { $a <=> $b } grep { $places->{$_} == 1 } keys %$places ];
}

sub winner {
	my ($self) = @_;
	my $winners = $self->winners;
	return @$winners == 1 ? $winners->[0] : undef;
}

sub is_draw {
	return @{ $_[0]->winners } > 1 ? 1 : 0;
}

sub seats {
	my ($self) = @_;
	return [ sort { $a <=> $b } keys %{ $self->places } ];
}

sub ranking {
	my ($self) = @_;
	my $places = $self->places;
	my %by;
	push @{ $by{ $places->{$_} } }, $_ for keys %$places;
	return [ map { [ sort { $a <=> $b } @{ $by{$_} } ] } sort { $a <=> $b } keys %by ];
}

sub stringify {
	my ($self) = @_;
	my $scores = $self->scores;
	my $order = join ', ', map {
		join(' and ', map { "seat $_" } @$_) . ' (' . ($scores->{ $_->[0] } // 0) . ')'
	} @{ $self->ranking };
	my $head = $self->is_draw ? 'Drawn' : 'Seat ' . $self->winner . ' wins';
	return $head . ' by ' . ($self->reason // 'unknown') . ': ' . $order;
}

1;

__END__

=head1 NAME

Game::Dominoes::Result - how a game ended, and in what order

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	my $result = $game->result;

	$result->winner;      # 2, or undef if it was drawn
	$result->places;      # { 1 => 2, 2 => 1, 3 => 3 }
	$result->scores;      # { 1 => 204, 2 => 250, 3 => 111 }
	$result->reason;      # 'target'
	$result->ranking;     # [ [2], [1], [3] ]
	$result->stringify;

=head1 DESCRIPTION

The whole finishing order, not just a winner.

At two seats "who won" says everything. At three and four, second is a real
result: it is what C<game_players.place> on peer2peergames.com records and what
the pairwise rating there consumes, so the engine produces the ranking and lets
the caller decide how much of it to use.

=head1 PROPERTIES

=head2 places

	$result->places;   # { 1 => 2, 2 => 1 }

The finishing order, seat to place. Places start at 1 and B<may repeat>: two
seats tied for second means two seats at place 2 and nobody at place 3, the
way a race result is written.

=head2 scores

	$result->scores;

Each seat's final score.

=head2 reason

	$result->reason;   # 'target'

One of C<target>, C<blocked>, C<resign> or C<timeout>.

B<C<timeout> is never produced by this engine.> It exists so that a server can
build a result of the same shape when a seat runs out of clock, which is not
something a game of dominoes knows about. L<Game::Checkers::Result> carries the
same value for the same reason.

=head1 FUNCTIONS

=head2 winner

	$result->winner;   # 2, or undef

The seat on place 1, or undef when more than one seat shares it. Undef means a
draw, not an error.

=head2 winners

	$result->winners;   # [2]

Every seat on place 1, in seat order.

=head2 is_draw

	$result->is_draw;

Whether more than one seat finished first.

=head2 seats

	$result->seats;

Every seat in the game, in seat order.

=head2 ranking

	$result->ranking;   # [ [2], [1, 3] ]

The seats in finishing order, one inner arrayref per place, so a tie stays
visible instead of being flattened into an arbitrary order.

=head2 reasons

	Game::Dominoes::Result->reasons;

Every reason this class accepts, as an arrayref.

=head2 stringify

	$result->stringify;

One line for a person.

=head1 SEE ALSO

L<Game::Dominoes>, which builds these.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Result

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
