package Game::Fanorona::Error;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.02';

our @CODES;
our %MESSAGE;
BEGIN {
    @CODES = qw(
        game_over
        not_a_side
        offer_standing
        no_offer
        own_offer
        chain_open
        nothing_to_stop
        bad_move
        off_board
        no_stone
        not_your_stone
        not_the_stone
        not_adjacent
        no_line
        point_taken
        same_direction
        point_revisited
        paika_in_chain
        takes_nothing
        choose_capture
        must_capture
    );
    %MESSAGE = (
        game_over       => 'the game is already over',
        not_a_side      => 'that is not one of the two sides',
        offer_standing  => 'a draw has already been offered',
        no_offer        => 'no draw has been offered',
        own_offer       => 'you cannot answer your own offer',
        chain_open      => 'a move is in progress: finish it or stop',
        nothing_to_stop => 'no move is in progress',
        bad_move        => 'that is not a move',
        off_board       => 'that point is not on the board',
        no_stone        => 'there is no stone there',
        not_your_stone  => 'that stone is not yours',
        not_the_stone   => 'the stone that is taking must go on, or stop',
        not_adjacent    => 'a stone steps to the next point along a line',
        no_line         => 'no line runs that way from there',
        point_taken     => 'a stone is standing there',
        same_direction  => 'a stone may not step twice running in the same direction',
        point_revisited => 'a stone may not come back to a point in the same move',
        paika_in_chain  => 'a stone that has taken may stop, and may not then move on without taking',
        takes_nothing   => 'that step takes nothing that way',
        choose_capture  => 'that step can take two ways: say which, A or W',
        must_capture    => 'a stone can be taken, so one must be',
    );
}

has code => (is => 'ro');

has message => (is => 'ro', default => '');

has move => (is => 'ro');

my $MAKING = 0;

sub BUILD {
    my ($self) = @_;
    Carp::croak('Game::Fanorona::Error: a refusal is made by Game::Fanorona::Error->of')
        unless $MAKING;
    return;
}

sub of {
    my ($class, $code, %extra) = @_;
    Carp::croak("Game::Fanorona::Error: no such refusal as '" . ($code // 'undef') . "'")
        unless defined $code && exists $MESSAGE{$code};
    $MAKING = 1;
    my $made = eval {
        $class->new(
            code    => $code,
            message => $MESSAGE{$code},
            (defined $extra{move} ? (move => "$extra{move}") : ()),
        );
    };
    my $died = $@;
    $MAKING = 0;
    Carp::croak($died) unless $made;
    return $made;
}

sub is {
    my ($self, $code) = @_;
    return defined $code && $self->code eq $code ? 1 : 0;
}

sub codes { @CODES }

sub message_for { $MESSAGE{ $_[1] // '' } }

sub known { defined $_[1] && exists $MESSAGE{ $_[1] } ? 1 : 0 }

1;

__END__

=head1 NAME

Game::Fanorona::Error - why a game of fanorona refused something

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Fanorona;

    my $game = Game::Fanorona->new;
    if (!$game->play('a1-a2')) {
        my $error = $game->error;
        print $error->code, ': ', $error->message, "\n";
        # point_taken: a stone is standing there
    }

=head1 DESCRIPTION

A refusal: a code a program can switch on, a sentence a person can read, and
the move it was about. L<Game::Fanorona> never dies because a move was not
legal. It returns nothing and leaves one of these in C<error>.

=head2 The codes

In the order they are looked for. When more than one would apply, the first
is the one given.

=over 4

=item game_over

The game has ended.

=item not_a_side

A side was asked for and what was given is neither C<white> nor C<black>.

=item offer_standing

A draw was offered while an offer was already on the table.

=item no_offer

A draw was accepted or declined and none had been offered.

=item own_offer

A side tried to answer its own offer.

=item chain_open

A whole move was played while a move was in progress.

=item nothing_to_stop

A stop was asked for and no move was in progress.

=item bad_move

Not a move at all: its shape is wrong.

=item off_board

A point that is not on this board.

=item no_stone

Nothing stands on the point the move starts from.

=item not_your_stone

The stone belongs to the side that is not to move.

=item not_the_stone

A move is in progress and this is a different stone.

=item not_adjacent

A step between points that are not next to each other.

=item no_line

No line runs that way from there: the edge of the board, or a diagonal from a
point that has none.

=item point_taken

A stone stands where the step would go.

=item same_direction

The direction of the step directly before, in the same move.

=item point_revisited

A point the stone has already stood on in this move.

=item paika_in_chain

A step that takes nothing, after one that took.

=item takes_nothing

The move says the step takes by approach or by withdrawal, and nothing is
there to take that way.

=item choose_capture

The step was written with no letter and could take two ways.

=item must_capture

A step that takes nothing, while some stone of the mover's could take.

=back

=head1 CONSTRUCTORS

=head2 of

    my $error = Game::Fanorona::Error->of('point_taken', move => 'a1-a2');

A refusal by its code. Croaks on a code that is not one. B<Not by C<new>>,
which croaks.

=head1 METHODS

=head2 code

=head2 message

=head2 move

The code, its sentence, and the move as it was given, when there was one.

=head2 is

    $error->is('must_capture')

True when that is the code.

=head1 CLASS METHODS

=head2 codes

Every code, in the order above.

=head2 message_for

    Game::Fanorona::Error->message_for('point_taken')

The sentence for a code, or C<undef>.

=head2 known

True for a code that is one.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
