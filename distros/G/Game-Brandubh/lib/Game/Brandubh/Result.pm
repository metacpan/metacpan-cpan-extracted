package Game::Brandubh::Result;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

our (%WIN, %DRAW);
BEGIN {
    %WIN  = map { $_ => 1 } qw(corner edge capture no_pieces resign);
    %DRAW = map { $_ => 1 } qw(repetition no_move ply_cap agreed);
}

has how => (is => 'ro');

has winner => (is => 'ro');

has seat => (is => 'ro');

has ply => (is => 'ro', default => 0);

has position => (is => 'ro');

sub BUILD {
    my ($self) = @_;
    my $how = $self->how;
    Carp::croak('Game::Brandubh::Result: a result says how the game ended')
        unless defined $how && ($WIN{$how} || $DRAW{$how});

    my $winner = $self->winner;
    if ($WIN{$how}) {
        Carp::croak("Game::Brandubh::Result: a game ended by $how has a winner, attackers or defenders")
            unless defined $winner && ($winner eq 'attackers' || $winner eq 'defenders');
        Carp::croak("Game::Brandubh::Result: a game ended by $how names the winner's seat")
            unless defined $self->seat;
    }
    else {
        Carp::croak("Game::Brandubh::Result: a game drawn by $how has no winner")
            if defined $winner || defined $self->seat;
    }
    return;
}

sub is_draw { $DRAW{ $_[0]->how } ? 1 : 0 }

sub loser {
    my ($self) = @_;
    my $winner = $self->winner;
    return undef unless defined $winner;
    return $winner eq 'attackers' ? 'defenders' : 'attackers';
}

sub by_players {
    my $how = $_[0]->how;
    return $how eq 'resign' || $how eq 'agreed' ? 1 : 0;
}

sub hows { sort(keys %WIN, keys %DRAW) }

1;

__END__

=head1 NAME

Game::Brandubh::Result - how a game of brandubh ended

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $result = $game->result;         # undef while the game is on

    if ($result) {
        print $result->how, "\n";                       # corner
        print $result->winner // 'nobody', "\n";        # defenders
        print "a draw\n" if $result->is_draw;
    }

=head1 DESCRIPTION

A finished game's ending, as a value that cannot be changed: how it ended, who
won if anybody did, after how many moves, and the position it stopped in.

L<Game::Brandubh> makes these. There is no result while a game is on.

=head2 How a game ends

=over 4

=item C<corner>

The king reached a corner. The defenders win.

=item C<edge>

The king reached the edge, in a rule set where the edge is the way out. The
defenders win.

=item C<capture>

The king was captured. The attackers win.

=item C<no_pieces>

The attackers have no piece left. The defenders win.

=item C<resign>

A seat resigned. The other side wins.

=item C<repetition>

A position occurred for the last time the rule set allows. A draw.

=item C<no_move>

The side to move could not move. A draw.

=item C<ply_cap>

The game reached its limit of moves. A draw.

=item C<agreed>

The two seats agreed a draw.

=back

=head1 METHODS

=head2 new

Made by L<Game::Brandubh>. B<Croaks> on an ending that is not one of the nine,
on a win with no winner, and on a draw with one.

=head2 how

One of the nine words above.

=head2 winner

C<attackers> or C<defenders>, or C<undef> for a draw.

=head2 loser

The other side, or C<undef> for a draw.

=head2 seat

The seat that won, C<p1> or C<p2>, or C<undef> for a draw.

=head2 is_draw

True for C<repetition>, C<no_move>, C<ply_cap> and C<agreed>.

=head2 by_players

True for C<resign> and C<agreed>: the two endings the board cannot show,
because they are something the players did.

=head2 ply

How many moves had been made when the game ended, counting both sides'.

=head2 position

The position the game stopped in, as a string.

=head2 hows

    my @words = Game::Brandubh::Result->hows;

The nine endings.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
