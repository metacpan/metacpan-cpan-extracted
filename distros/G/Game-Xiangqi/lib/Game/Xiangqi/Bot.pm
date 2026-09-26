package Game::Xiangqi::Bot;

use 5.010;
use strict;
use warnings;

use Digest::SHA ();
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;

our $VERSION = '0.01';

my $N = 'Game::Xiangqi::Notation';

our @LADDER = (400, 6_000, 6_000, 60_000);

our $LEVEL;

sub level_for {
    my ($class, $seed) = @_;
    return $LEVEL if defined $LEVEL;
    my $n = unpack 'N', Digest::SHA::sha256("xiangqi-level:$seed");
    return $LADDER[ $n % scalar @LADDER ];
}

sub tiebreak_seed {
    my ($class, $seed, $seat) = @_;
    return unpack 'N', Digest::SHA::sha256("xiangqi-bot:$seed:$seat");
}

sub choose {
    my ($class, $game, $seat) = @_;
    return undef unless $game->status eq 'active';
    return undef unless defined $game->turn && $game->turn eq $seat;

    my $budget = $class->level_for($game->_held_seed);
    my $tie    = $class->tiebreak_seed($game->_held_seed, $seat);

    my ($mv, $nodes, $depth, $score, $stopped) =
        $game->position->search($budget, $tie);
    return undef unless $mv;
    return $N->iccs_of($mv);
}

sub hint {
    my ($class, $game, $seat) = @_;
    local $LEVEL = $LADDER[-1];
    return $class->choose($game, $seat);
}

1;

__END__

=head1 NAME

Game::Xiangqi::Bot - the opponent, bounded in nodes

=head1 SYNOPSIS

    my $iccs = Game::Xiangqi::Bot->choose($game, 'p2');
    my $help = Game::Xiangqi::Bot->hint($game, 'p1');

=head1 DESCRIPTION

A budget in NODES and never in seconds, so a loaded machine chooses the same
move as an idle one and a bot game replays. The rung is drawn from the game's
seed, one per game, from C<@LADDER>, which is written weakest first.

C<hint> always answers at the top budget whatever the game drew.

=head2 The ladder, measured

A rung is a B<node budget> and not a 1, 2, 3, because a budget is what this
engine's dial actually is, and C<@LADDER> is written B<weakest first> because
C<hint> reaches for the last entry.

The spacing was measured over sixty games a pair with the colours alternated,
against a 60% bar written down before the run: rung 40000 beat rung 8000 by
69.2%, while rung 8000 beat rung 1500 by only 56.7%. Those two steps are one ply
each, and B<the plies are not worth the same>: depth 2 already sees a capture and
its reply, so the step to depth 3 buys a quieter move where the step to depth 4
buys an exchange. The bottom rung was therefore dropped to depth 1, which is also
what makes it beatable by a person.

B<The re-spaced ladder has not itself been played.> Until it has, this section
describes the measurement the current spacing was derived from and not a
measurement of the current spacing.

=head2 The seat is in the tie-break

Equal-scoring root moves are separated by a seed mixed from the game's seed
B<and the seat>. Without the seat both bots in a bot-versus-bot game are the
same player, and a soak of them measures nothing at all.

=head1 METHODS

=head2 choose

    my $iccs = Game::Xiangqi::Bot->choose($game, 'p2');

The move this seat should play, in ICCS, or C<undef> if the game is over or it is
not that seat's turn. The rung is drawn from the game's seed, so one game plays one
opponent throughout and a replay reaches the same moves.

=head2 hint

    my $iccs = Game::Xiangqi::Bot->hint($game, 'p1');

The same, B<always at the top budget> whatever rung this game drew. Somebody asking
for help is not asking for a beginner's answer.

=head2 level_for

    my $budget = Game::Xiangqi::Bot->level_for($seed);

The node budget this seed draws from C<@LADDER>. Returns C<$LEVEL> instead when that
is set, which is how a test or a deployment pins every game to one rung.

=head2 tiebreak_seed

    my $n = Game::Xiangqi::Bot->tiebreak_seed($seed, $seat);

The number handed to the search to separate equal-scoring moves, mixed from the
game's seed B<and the seat>. Two seats of one game get two different numbers, which
is the whole point: without it both bots in a bot-versus-bot game are the same
player and a soak measures nothing.

=cut
