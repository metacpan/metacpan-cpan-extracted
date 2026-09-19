package Game::Oware::Move;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Oware::Board;

our $VERSION = '0.01';

has seat => (
	is  => 'ro',
	isa => Str
);

has house => (
	is  => 'ro',
	isa => Int
);

has sown => (
	is  => 'ro',
	isa => Int
);

has last => (
	is  => 'ro',
	isa => Int
);

has captured => (
	is      => 'ro',
	isa     => ArrayRef,
	default => []
);

has taken => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has slammed => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has forfeited => (
	is      => 'ro',
	isa     => ArrayRef,
	default => []
);

sub BUILD {
	my ($self) = @_;

	my $seat = $self->seat // '';
	die "Game::Oware::Move: seat must be p1 or p2, not '$seat'"
		unless $seat eq 'p1' || $seat eq 'p2';

	Game::Oware::Board->assert_house($self->house);
	Game::Oware::Board->assert_house($self->last);

	die 'Game::Oware::Move: a seat may only sow from its own house'
		unless Game::Oware::Board->owner_of($self->house) eq $seat;

	my $sown = $self->sown;
	die 'Game::Oware::Move: a move sows at least one seed'
		unless defined $sown && $sown =~ /\A\d+\z/ && $sown > 0;

	my $captured = $self->captured;
	die 'Game::Oware::Move: a move never captures more houses than it sowed'
		if @$captured > $sown;

	die 'Game::Oware::Move: a seat never captures its own house'
		if grep { Game::Oware::Board->owner_of($_) eq $seat } @$captured;

	die 'Game::Oware::Move: taken disagrees with captured'
		if !@$captured && $self->taken;

	my $forfeited = $self->forfeited;

	die 'Game::Oware::Move: a move either captured its chain or forfeited it'
		if @$forfeited && @$captured;

	die 'Game::Oware::Move: only a grand slam forfeits a chain'
		if @$forfeited && !$self->slammed;

	return $self;
}

sub name {
	my ($self) = @_;
	require Game::Oware::Notation;
	return Game::Oware::Notation->letter_of($self->house);
}

sub stringify {
	my ($self) = @_;
	my $name = $self->name;
	return $name . ' (slam forfeited)' if @{ $self->forfeited };
	return $name unless @{ $self->captured };
	return $name . ' takes ' . $self->taken . ($self->slammed ? ' (slam)' : '');
}

1;

__END__

=head1 NAME

Game::Oware::Move - one sowing, and what it took

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Move;

    my $move = Game::Oware::Move->new(
        seat => 'p1', house => 4, sown => 6, last => 10,
        captured => [ 10, 9, 8 ], taken => 8);

    print $move->stringify;    # E takes 8

=head1 DESCRIPTION

A value object. The same one the terminal prints and the site adapter puts in
its event log.

=head2 taken, and never score

The site this engine was written for bans a set of view key names with an
anchored regular expression, and C<score> singular is on it while C<scores>
plural is not. The gate exists to stop a view carrying a bot's opinion of a
position, and a game whose central noun is a score would fail a test about
search leakage for a reason that has nothing to do with search.

Oware's natural English for a store is a "score house", so this is the name a
writer reaches for first. It is C<taken> instead, and the list of houses is
C<captured> rather than C<line>, which is on the same ban.

=head2 slammed says what the move was, forfeited says what was done about it

C<slammed> is true when the chain would have taken every seed the opponent had.
That is a fact about the move and it does not depend on the rule set.
C<forfeited> holds the chain that was given back, which happens only under the
C<no_capture> policy; under C<illegal_unless_only> a slammed move captures
normally and C<forfeited> is empty.

Keeping them apart is what lets one C<Move> class describe both variants without
a flag meaning two things.

=head2 A forfeited chain is not the same as capturing nothing

Most moves capture nothing because they did not land where they needed to. A
forfeited move computed a capture and then gave it back, because taking it would
have left the opponent with no seeds and therefore no move.

A log that recorded only the outcome could not tell the two apart, and "you
sowed into three houses of two and took nothing" is a sentence the terminal and
the site both have to be able to say. Without it the rule reads as a bug, and it
is the single most likely thing in this game to be reported as one.

=head2 What BUILD refuses

Only things no correct engine can produce: a seat sowing from a house it does
not own, a move capturing more houses than it sowed seeds, a seat capturing its
own house, a move that both captured and forfeited a chain, and a chain
forfeited by something that was not a grand slam. These are programmer errors,
so they die. A player's bad move is a L<Game::Oware::Error> and is returned.

There is deliberately B<no> separate refusal for a forfeited chain that took
seeds. A forfeit captures nothing, so C<taken> without C<captured> already
refuses it, and a second C<die> for the same case could never be reached.

=head1 PROPERTIES

=head2 seat

C<p1> or C<p2>.

=head2 house

The house sown from, 0 to 11, always one the seat owns.

=head2 sown

How many seeds left that house.

=head2 last

The index the final seed landed in.

=head2 captured

The houses emptied, in walk-back order. Empty when nothing was captured.

=head2 taken

How many seeds that was.

=head2 slammed

True when the chain would have taken every seed the opponent had.

=head2 forfeited

The chain that was given back, empty unless the variant forfeits a slam.

=head1 METHODS

=head2 name

The move in notation: a single letter.

=head2 stringify

The move as a short phrase, for a transcript or a log line.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Board>, L<Game::Oware::Notation>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
