package Game::Shogi::Bot;

use 5.014;
use strict;
use warnings;

use Digest::SHA ();
use Game::Shogi::Engine ();

our $VERSION = '0.01';

our @LADDER = (400, 6_000, 60_000, 300_000);

our $LEVEL;

sub level_for {
    my ($class, $seed) = @_;
    return $LEVEL if defined $LEVEL;
    my $n = unpack 'N', Digest::SHA::sha256('shogi-level:' . ($seed // ''));
    return $LADDER[ $n % scalar @LADDER ];
}

sub tiebreak_seed {
    my ($class, $seed, $side) = @_;
    return unpack 'N', Digest::SHA::sha256('shogi-bot:' . ($seed // '') . ':' . ($side // ''));
}

sub choose {
    my ($class, $game, $side, %opt) = @_;
    return undef unless defined $game && $game->status eq 'active';
    return undef unless defined $side && defined $game->turn && $game->turn eq $side;
    my $budget = $opt{nodes} // $class->level_for($opt{seed});
    return scalar $game->board->search(
        nodes   => $budget,
        seed    => $class->tiebreak_seed($opt{seed}, $side),
        history => [ $game->history ],
    );
}

sub declares {
    my ($class, $game, $side) = @_;
    return 0 unless defined $game && defined $side && defined $game->turn && $game->turn eq $side;
    return $game->can_declare ? 1 : 0;
}

sub hint {
    my ($class, $game, $side, %opt) = @_;
    return $class->choose($game, $side, %opt, nodes => $LADDER[-1]);
}

1;

__END__

=head1 NAME

Game::Shogi::Bot - the opponent, bounded in nodes

=head1 SYNOPSIS

    my $usi  = Game::Shogi::Bot->choose($game, 'w', seed => $seed);
    my $help = Game::Shogi::Bot->hint($game, 'b');
    $game->declare if Game::Shogi::Bot->declares($game, 'w');

=head1 DESCRIPTION

A budget in NODES and never in seconds, so a loaded machine chooses the same
move as an idle one and a bot game replays. The rung is drawn from the game's
seed, one per game, from C<@LADDER>, written weakest first.

=head2 The ladder, measured

See F<plan_game_shogi/08-the-search-and-the-ladder.md>, which records each
rung against the one below, with the date and the number of games.

=head2 The seat is in the tie-break

Equal-scoring moves are separated by a seed mixed from the game's seed B<and
the side>. Without the side both bots of one game are the same player, and a
game between them measures nothing.

=head1 VARIABLES

=head2 @LADDER

The node budgets, weakest first.

=head2 $LEVEL

When set, every game plays this budget.

=head1 METHODS

=head2 choose

    my $usi = Game::Shogi::Bot->choose($game, 'w', seed => $seed, nodes => $n);

The move this side should play, as USI, or C<undef> when the game is over or
it is not this side's turn. The budget is C<nodes> when given, else the rung
the seed draws.

=head2 declares

True when it is this side's turn and it may declare the impasse, which wins.
A bot that may declares.

=head2 hint

The same as L</choose>, B<always at the top budget>. Somebody asking for help
is not asking for a beginner's answer.

=head2 level_for

    Game::Shogi::Bot->level_for($seed)

The node budget this seed draws from C<@LADDER>, or C<$LEVEL> when that is
set.

=head2 tiebreak_seed

    Game::Shogi::Bot->tiebreak_seed($seed, $side)

The number handed to the search to separate equal-scoring moves, mixed from
the game's seed and the side.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
