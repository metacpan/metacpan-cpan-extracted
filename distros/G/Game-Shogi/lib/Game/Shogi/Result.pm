package Game::Shogi::Result;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my %HOW = map { $_ => 1 } qw(mate no_move resign sennichite perpetual_check impasse_declared cap);

has how => (is => 'ro');

has winner => (is => 'ro');

has ply => (is => 'ro', default => 0);

sub BUILD {
    my ($self) = @_;
    my $how = $self->how;
    Carp::croak("Game::Shogi::Result: '" . ($how // 'undef') . "' is not how a game ends")
        unless defined $how && $HOW{$how};
    my $winner = $self->winner;
    Carp::croak("Game::Shogi::Result: the winner is 'b', 'w' or undef, not '$winner'")
        if defined $winner && $winner ne 'b' && $winner ne 'w';
    my $ply = $self->ply;
    Carp::croak("Game::Shogi::Result: the ply is a count, not '" . ($ply // 'undef') . "'")
        unless defined $ply && $ply =~ /\A[0-9]+\z/;
    return;
}

sub loser {
    my $w = $_[0]->winner;
    return defined $w ? ($w eq 'b' ? 'w' : 'b') : undef;
}

sub is_draw { defined $_[0]->winner ? 0 : 1 }

1;

__END__

=head1 NAME

Game::Shogi::Result - how a game of shogi ended

=head1 SYNOPSIS

    my $board = Game::Shogi::Engine->new(sfen => $sfen);
    if (my $r = $board->outcome) {
        printf "%s wins: %s, after %d plies\n", $r->winner, $r->how, $r->ply;
    }

=head1 DESCRIPTION

A value: who won, how, and after how many plies. L<Game::Shogi::Engine>
hands one back from C<outcome> and C<resign>.

=head1 ATTRIBUTES

=head2 how

C<mate>, when the side to move is in check and has no legal move;
C<no_move>, when it has no legal move and is not in check, which is a loss
in shogi and not a draw; C<resign>; C<sennichite>, a draw by the fourth
repetition of a position; C<perpetual_check>, a loss for the side that kept
checking through it; C<impasse_declared>, a win by the impasse declaration;
or C<cap>, a draw at the move cap.

=head2 winner

C<'b'> or C<'w'>, or C<undef> for a draw.

=head2 ply

How many plies had been played: the board's move number less one.

=head1 METHODS

=head2 loser

The other side, or C<undef> for a draw.

=head2 is_draw

True when nobody won.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
