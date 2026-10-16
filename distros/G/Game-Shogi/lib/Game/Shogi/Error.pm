package Game::Shogi::Error;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my @CODES = qw(
    bad_move not_your_piece not_in_hand cannot_reach occupied
    promote_not_allowed promote_required dead_piece two_pawns in_check pawn_drop_mate
    game_over not_your_turn cannot_declare nothing_to_undo
);

my %MESSAGE = (
    bad_move            => 'that is not a move',
    not_your_piece      => 'there is no piece of yours there',
    not_in_hand         => 'you have none of that piece in hand',
    cannot_reach        => 'that piece cannot move there',
    occupied            => 'a piece cannot be dropped onto another',
    promote_not_allowed => 'that piece may not promote on that move',
    promote_required    => 'that piece must promote on that move',
    dead_piece          => 'a piece cannot be dropped where it could never move',
    two_pawns           => 'you already have an unpromoted pawn on that file',
    in_check            => 'that would leave your king in check',
    pawn_drop_mate      => 'a pawn may not be dropped to give mate',
    game_over           => 'the game is already over',
    not_your_turn       => 'it is not your turn',
    cannot_declare      => 'the impasse may not be declared',
    nothing_to_undo     => 'there is no move to take back',
);

my @FAULT = (undef, @CODES[ 0 .. 10 ]);

has code => (is => 'ro');

has message => (is => 'ro');

sub BUILD {
    my ($self) = @_;
    my $code = $self->code;
    Carp::croak("Game::Shogi::Error: no such refusal '" . ($code // 'undef') . "'")
        unless defined $code && exists $MESSAGE{$code};
    return;
}

sub throw {
    my ($class, $code, $detail) = @_;
    Carp::croak("Game::Shogi::Error: no such refusal '" . ($code // 'undef') . "'")
        unless defined $code && exists $MESSAGE{$code};
    my $message = $MESSAGE{$code};
    $message .= ": $detail" if defined $detail && length $detail;
    return $class->new(code => $code, message => $message);
}

sub of_fault {
    my ($class, $fault) = @_;
    return undef unless defined $fault && $fault =~ /\A[0-9]+\z/ && $fault >= 1 && $FAULT[$fault];
    return $class->throw($FAULT[$fault]);
}

sub codes       { @CODES }
sub known       { defined $_[1] && exists $MESSAGE{ $_[1] } ? 1 : 0 }
sub message_for { defined $_[1] ? $MESSAGE{ $_[1] } : undef }
sub stringify   { $_[0]->message }

1;

__END__

=head1 NAME

Game::Shogi::Error - a refusal, returned and never thrown

=head1 SYNOPSIS

    my $refusal = $game->play('5h4g');
    if ($refusal) {
        print $refusal->code, "\n";      # in_check
        print $refusal->message, "\n";   # that would leave your king in check
    }

=head1 DESCRIPTION

A refused move comes back as one of these. It is B<not> thrown: a refused move
is an ordinary thing for a player to do, and a caller should not have to wrap
every move in an C<eval>. C<die> is kept for programmer error, such as a
refusal code that does not exist. This is Game::Xiangqi's rule, kept.

=head1 CODES

In the order the board asks a move's faults, so a move with two gives the
first: C<bad_move>, C<not_your_piece>, C<not_in_hand>, C<cannot_reach>,
C<occupied>, C<promote_not_allowed>, C<promote_required>, C<dead_piece>,
C<two_pawns>, C<in_check>, C<pawn_drop_mate>. Then those only a game gives:
C<game_over>, C<not_your_turn>, C<cannot_declare> and C<nothing_to_undo>.

=head1 ATTRIBUTES

=head2 code

The refusal, one of the codes above.

=head2 message

The refusal in words, as a player would read it, with the detail after a
colon when there is one (C<cannot_declare> says which condition failed).

=head1 METHODS

=head2 throw

    Game::Shogi::Error->throw('game_over')

Makes a refusal and RETURNS it, the name Game::Xiangqi uses. Croaks for a
code that does not exist.

=head2 of_fault

The refusal for one of L<Game::Shogi::Engine>'s C<FAULT_> codes, or C<undef>
for C<FAULT_OK>.

=head2 codes

Every code, in order.

=head2 known

True for a code that exists.

=head2 message_for

The message for a code.

=head2 stringify

The message.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
