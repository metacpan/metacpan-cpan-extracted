package Game::Sternhalma::Bot;

use 5.014;
use strict;
use warnings;

use Carp ();

our $VERSION = '0.01';

# THE RUNGS, weakest first. 0 is a random choice among moves that go forward;
# 1 looks one ply ahead; 2 and 3 search, by a budget of positions looked at.
# phase 07's ladder measured them (plan_game_sternhalma/07, Built).
our %RUNG = (
    0 => { random => 1 },
    1 => { budget => 1_000_000, depth => 1 },
    2 => { budget => 10_000 },
    3 => { budget => 100_000 },
);

sub rungs { sort { $a <=> $b } keys %RUNG }

sub choose {
    my ($class, $game, %with) = @_;
    my $info = $class->think($game, %with) or return undef;
    return $info->{pass} ? { kind => 'pass' } : { kind => 'move', from => $info->{from}, to => $info->{to} };
}

sub think {
    my ($class, $game, %with) = @_;
    my ($board, @history);
    if (ref $game && $game->can('board')) { $board = $game->board; @history = $game->history($game->to_move) }
    elsif (ref $game && $game->can('search')) { $board = $game }
    else { Carp::croak('Game::Sternhalma::Bot: this takes a Game::Sternhalma or a Game::Sternhalma::Engine') }
    @history = @{ $with{history} } if $with{history};
    return undef if $board->over;
    my $rung = defined $with{rung} ? $with{rung} : (rungs())[-1];
    my $r = $RUNG{$rung} or Carp::croak("Game::Sternhalma::Bot: there is no rung $rung; there are " . join(', ', rungs()));
    my $seed = defined $with{seed} ? $with{seed} : 1;
    Carp::croak('Game::Sternhalma::Bot: a seed is a whole number') unless $seed =~ /\A[0-9]{1,15}\z/;
    $seed = ($seed * 1_000_003 + $board->ply) % 1_000_000_000_000;
    my $out;
    if ($r->{random}) {
        $out = $board->random_forward($seed + 1);
        $out->{nodes} = '0';
        $out->{depth} = 0;
    }
    else {
        $out = $board->search(budget => $r->{budget}, depth => $r->{depth} // 0, seed => $seed + 1,
                              avoid => \@history, ($with{weights} ? (weights => $with{weights}) : ()));
    }
    $out->{rung} = $rung;
    return $out;
}

1;

__END__

=head1 NAME

Game::Sternhalma::Bot - players for a game of sternhalma, from weakest to strongest

=head1 SYNOPSIS

    use Game::Sternhalma;
    use Game::Sternhalma::Bot;

    my $game = Game::Sternhalma->new(seats => 3);
    until ($game->over) {
        my $move = Game::Sternhalma::Bot->choose($game, rung => 1, seed => 7);
        $game->play($move);
        last if $game->ply >= 9;
    }

=head1 DESCRIPTION

Four rungs, weakest first. Rung 0 picks at random among the moves that take
a piece nearer home. Rung 1 takes the move that leaves it best placed
against its nearest rival, one ply ahead. Rungs 2 and 3 search ahead, for a
budget of positions looked at, never of seconds, so the same rung plays the
same move on any machine. The same game, rung and seed always give the same
move. A searching rung never puts its pieces back into an arrangement they
have already had while it has another move: without that, searching seats
can shuffle pieces inside their homes for ever, each waiting for another to
make a ladder.

=head1 METHODS

=head2 choose

    my $move = Game::Sternhalma::Bot->choose($game, rung => 3, seed => 7);

A move for the seat to move, as L<Game::Sternhalma/play> takes it: C<< {
kind => 'move', from, to } >> or C<< { kind => 'pass' } >>. C<undef> once the
game is over. C<$game> is a L<Game::Sternhalma>, whose history the bot
reads, or a L<Game::Sternhalma::Engine>, with C<< history => [ keys ] >>,
the L<Game::Sternhalma::Engine/own_key>s the seat to move has had, if it
has one. The rung defaults to the strongest.

=head2 think

The same, with what the choice cost: C<from>, C<to>, C<pass>, C<nodes>,
C<depth>, C<score> and C<rung>.

=head2 rungs

The rungs there are, weakest first.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
