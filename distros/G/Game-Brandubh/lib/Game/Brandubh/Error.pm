package Game::Brandubh::Error;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

our @FLAGS;
BEGIN {
    @FLAGS = qw(
        bad_move
        game_over
        not_a_seat
        not_your_turn
        no_piece
        not_your_piece
        no_move
        not_a_line
        path_blocked
        throne_closed
        corner_closed
        no_offer
        own_offer
        offer_standing
    );
}

our %MESSAGE;
BEGIN {
    %MESSAGE = (
        bad_move       => 'that is not a move',
        game_over      => 'the game is already over',
        not_a_seat     => 'that is not one of the two seats',
        not_your_turn  => 'it is not your turn',
        no_piece       => 'there is no piece there',
        not_your_piece => 'that piece is not yours',
        no_move        => 'that piece did not move',
        not_a_line     => 'a piece moves in a straight line along a row or a column',
        path_blocked   => 'another piece is in the way',
        throne_closed  => 'no piece may stop on the throne',
        corner_closed  => 'only the king may stand on a corner',
        no_offer       => 'no draw has been offered',
        own_offer      => 'you cannot answer your own offer',
        offer_standing => 'a draw has already been offered',
    );
}

has [@FLAGS] => (is => 'ro');

has message => (is => 'ro', default => '');

has move => (is => 'ro');

sub throw {
    my ($class, $flag, %extra) = @_;
    Carp::croak("Game::Brandubh::Error: no such refusal as '" . ($flag // 'undef') . "'")
        unless defined $flag && exists $MESSAGE{$flag};
    return $class->new(
        $flag   => 1,
        message => $MESSAGE{$flag},
        (defined $extra{move} ? (move => "$extra{move}") : ()),
    );
}

sub BUILD {
    my ($self) = @_;
    my @set = grep { $self->$_ } @FLAGS;
    Carp::croak('Game::Brandubh::Error: a refusal is made by throw, and names exactly one thing')
        unless @set == 1;
    return;
}

sub code {
    my ($self) = @_;
    for my $flag (@FLAGS) {
        return $flag if $self->$flag;
    }
    return undef;
}

sub flags { @FLAGS }

sub message_for { $MESSAGE{ $_[1] // '' } }

sub known { defined $_[1] && exists $MESSAGE{ $_[1] } ? 1 : 0 }

1;

__END__

=head1 NAME

Game::Brandubh::Error - a refusal, returned and never thrown

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $refused = $game->play('a4a7');

    if ($refused) {
        print $refused->code, "\n";         # corner_closed
        print $refused->message, "\n";      # only the king may stand on a corner
        print "the corner\n" if $refused->corner_closed;
    }

=head1 DESCRIPTION

What L<Game::Brandubh> hands back when it will not do what it was asked. It is
an object and never a string to match against: ask it which refusal it is with
C<code>, or with the accessor of that name.

A refusal is an ordinary thing for a player to cause, so it is B<returned>.
Nothing here dies. The game is left exactly as it was.

=head2 The refusals

=over 4

=item C<bad_move>

The string is not written as a move.

=item C<game_over>

The game has ended.

=item C<not_a_seat>

A seat was named that is neither C<p1> nor C<p2>.

=item C<not_your_turn>

A seat was named and it is the other seat's move.

=item C<no_piece>

Nothing stands on the square the move leaves.

=item C<not_your_piece>

The piece there belongs to the side that is not to move.

=item C<no_move>

The move leaves a square and arrives on the same one.

=item C<not_a_line>

The two squares share neither a rank nor a file.

=item C<path_blocked>

Another piece stands on the way, or on the square to be reached.

=item C<throne_closed>

The move would stop on the throne, or would cross a throne the rule set does
not let it cross.

=item C<corner_closed>

A piece other than the king would stop on a corner.

=item C<no_offer>

A draw was accepted or declined when none had been offered.

=item C<own_offer>

A seat tried to answer the draw it offered itself.

=item C<offer_standing>

A draw was offered while an offer was already waiting for its answer.

=back

=head1 METHODS

=head2 throw

    my $refusal = Game::Brandubh::Error->throw('path_blocked', move => 'd1d3');

Makes a refusal. Despite the name it B<returns> the object; the name is the
one the sibling distributions use. C<move> is optional and is kept as given.
B<Croaks> on a name that is not one of the refusals, because that is a mistake
in the caller and not something a player did.

A refusal is made by C<throw> and by nothing else: C<new> croaks unless exactly
one refusal is named.

=head2 code

The name of the refusal, one of the list above.

=head2 message

A sentence in English saying what was wrong.

=head2 move

The move that was refused, as it was given, when there was one.

=head2 bad_move

=head2 game_over

=head2 not_a_seat

=head2 not_your_turn

=head2 no_piece

=head2 not_your_piece

=head2 no_move

=head2 not_a_line

=head2 path_blocked

=head2 throne_closed

=head2 corner_closed

=head2 no_offer

=head2 own_offer

=head2 offer_standing

True on the refusal of that name and false on every other.

=head2 flags

    my @names = Game::Brandubh::Error->flags;

The names of all the refusals.

=head2 message_for

    my $sentence = Game::Brandubh::Error->message_for('no_piece');

The sentence for a name, or C<undef> for a name that is not a refusal.

=head2 known

    if (Game::Brandubh::Error->known($name)) { ... }

True when the name is one of the refusals.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
