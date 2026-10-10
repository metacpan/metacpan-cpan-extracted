package Game::RoyalUr::Error;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my (@CODES, %MESSAGE);
BEGIN {
    @CODES = qw(
        game_over
        no_roll
        bad_move
        no_piece
        not_your_piece
        wrong_distance
        own_piece
        safe_rosette
        overshoot
        bad_record
    );
    %MESSAGE = (
        game_over      => 'the game is already over',
        no_roll        => 'there is no roll to play: the record this game was read from ends here',
        bad_move       => 'that is not a move',
        no_piece       => 'you have no piece there',
        not_your_piece => 'that piece is not yours',
        wrong_distance => 'a piece moves exactly as far as the roll',
        own_piece      => 'one of your own pieces is already on that square',
        safe_rosette   => 'a piece on a rosette cannot be captured',
        overshoot      => 'a piece leaves the board only on the exact roll',
        bad_record     => 'the record does not agree with the game it describes',
    );
}

has code => (is => 'ro');

has message => (is => 'ro');

has detail => (is => 'ro');

sub codes { @CODES }

sub message_for {
    my ($class, $code) = @_;
    return $MESSAGE{ $code // '' };
}

sub of {
    my ($class, $code, %detail) = @_;
    Carp::croak("Game::RoyalUr::Error: no such refusal as '" . ($code // 'undef') . "'")
        unless defined $code && exists $MESSAGE{$code};
    return $class->new(code => $code, message => $MESSAGE{$code}, detail => { %detail });
}

1;

__END__

=head1 NAME

Game::RoyalUr::Error - why a move of the Royal Game of Ur was refused

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    $game->play('a2-d2') or do {
        my $error = $game->error;
        print $error->code, ': ', $error->message, "\n";
        # safe_rosette: a piece on a rosette cannot be captured
    };

=head1 DESCRIPTION

A refusal: which rule a move broke, in a word a program can act on and a
sentence a person can read. A refused move is returned and never thrown, and
leaves the game exactly as it was.

=head2 The codes

=over 4

=item C<game_over>

The game has ended.

=item C<no_roll>

There is no roll to play. Only a game read from a record that carried no seed
answers this, when it is asked to play on past the record's end.

=item C<bad_move>

The text is not a move: not two places with a dash between them.

=item C<no_piece>

The square named has no piece on it, or the hand is empty.

=item C<not_your_piece>

The piece belongs to the side not to move.

=item C<wrong_distance>

The square named is not as far from the piece as the roll.

=item C<own_piece>

One of the mover's own pieces stands where the piece would land.

=item C<safe_rosette>

An enemy piece stands where the piece would land, on a rosette, under a rule
set in which a rosette protects it.

=item C<overshoot>

The roll would carry the piece past the end of its route. A piece leaves the
board only on the exact roll.

=item C<bad_record>

A record being replayed does not describe a game that could have been played:
its side, its roll or its move at some turn is not what the game has there.

=back

A move can be wrong in more than one way. The first that applies, in the
order above, is the one reported.

=head1 METHODS

=head2 of

    my $error = Game::RoyalUr::Error->of('overshoot', roll => 3, from => 'h1');

A refusal with that code and its sentence. Anything after the code is kept as
the detail. B<Croaks> on a code that is not one of the ten.

=head2 code

The word.

=head2 message

The sentence, in English.

=head2 detail

A hash reference of whatever is known about the refusal: the roll, the
places named, and for C<bad_record> the turn at which the record went wrong.

=head2 codes

The ten codes, in the order they are checked.

=head2 message_for

    my $sentence = Game::RoyalUr::Error->message_for('overshoot');

The sentence for a code, or C<undef> for a word that is not one.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
