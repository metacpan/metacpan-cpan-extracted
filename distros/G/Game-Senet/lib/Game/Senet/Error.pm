package Game::Senet::Error;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my (@CODES, %MESSAGE);
BEGIN {
    @CODES = qw(
        game_over bad_move no_roll no_piece not_your_piece bound_piece
        wrong_distance forward_first no_back must_land_26 no_exit
        blockade own_piece safe_house protected
        bad_record bad_position
    );
    %MESSAGE = (
        game_over      => 'the game is already over',
        bad_move       => 'that is not a move',
        no_roll        => 'there is no throw to play: the record this game was read from ends here',
        no_piece       => 'there is no piece on that house',
        not_your_piece => 'that piece is not yours',
        bound_piece    => 'this throw belongs to the piece that has just reached the House of Happiness',
        wrong_distance => 'a piece moves exactly as many houses as the throw is worth',
        forward_first  => 'a piece moves back only when no piece can move forward',
        no_back        => 'that piece cannot move back',
        must_land_26   => 'every piece must stop on the House of Happiness before it goes further',
        no_exit        => 'a piece on that house cannot move with this throw',
        blockade       => 'a row of the other side\'s pieces blocks the way, and cannot be passed',
        own_piece      => 'one of your own pieces is already on that house',
        safe_house     => 'a piece on that house is safe and cannot be swapped',
        protected      => 'that piece is protected by the piece beside it',
        bad_record     => 'the record does not agree with the game it describes',
        bad_position   => 'that position is not one this game can start from',
    );
}

has code => (is => 'ro', default => 'bad_move');

has message => (is => 'ro');

has detail => (is => 'ro');

sub codes { @CODES }

sub message_for {
    my ($class, $code) = @_;
    return $MESSAGE{ $code // '' };
}

sub of {
    my ($class, $code, %detail) = @_;
    Carp::croak("Game::Senet::Error: no such refusal as '" . ($code // 'undef') . "'")
        unless defined $code && exists $MESSAGE{$code};
    return $class->new(code => $code, message => $MESSAGE{$code}, detail => { %detail });
}

1;

__END__

=head1 NAME

Game::Senet::Error - why a move, a record or a position was refused

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    $game->play('12-15') or print $game->error->code, ': ', $game->error->message, "\n";

=head1 DESCRIPTION

A refusal: a code a program can switch on, an English sentence a terminal can
show, and the detail of what was asked. A game that refuses a move returns
C<undef> and keeps one of these in C<error>.

=head1 CODES

In the order a move is asked about them: C<game_over>, C<bad_move>, C<no_roll>,
C<no_piece>, C<not_your_piece>, C<bound_piece>, C<wrong_distance>,
C<forward_first>, C<no_back>, C<must_land_26>, C<no_exit>, C<blockade>,
C<own_piece>, C<safe_house>, C<protected>. And C<bad_record> for a record that
disagrees with the game it describes, C<bad_position> for a position a game
cannot start from.

=head1 METHODS

=head2 of

    my $error = Game::Senet::Error->of($code, %detail);

The refusal with that code. A code that is not one croaks.

=head2 code

=head2 message

=head2 detail

A hash: the throw, the roll, the houses, the ply, as the refusal had them.

=head2 codes

Every code, in order.

=head2 message_for

    my $sentence = Game::Senet::Error->message_for($code);

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
