package FnSolve;

# WHAT A POSITION IS WORTH BY FORCE, worked out through the game itself. Every
# position reachable from the ones given is made, its moves are the engine's,
# a game that has ended is the engine's ruling, and the values are found by
# working backwards from the endings: a position is won if some move reaches a
# position lost for the other side, lost if every move reaches one won for
# them, and a draw if neither is ever established.
#
# Repetition and the quiet limit are OFF: this is about what can be forced.
# What is ON is the ruling that a side with no move has lost.

use strict;
use warnings;
use Exporter 'import';
use Game::Fanorona::Rules ();

our @EXPORT_OK = qw(solve);

my $OFF = { quiet_limit => 0, repeat => 0 };

# Returns (\%value, \%next): for every position reached, W, L or nothing (a
# draw) for the side to move there; and for every position, a list of
# [ move, position after ].
sub solve {
    my ($format, @start) = @_;
    my (%next, %value);
    my @todo = @start;
    while (defined(my $position = shift @todo)) {
        next if exists $next{$position};
        my $game = Game::Fanorona::Rules->new(position => $position, variant => $OFF);
        if ($game->over) {
            $next{$position} = [];
            $value{$position} = $game->winner == $game->side ? 'W' : 'L';
            next;
        }
        my @after;
        for my $move ($game->moves) {
            $game->play_move($move) or die 'a listed move was refused';
            push @after, [ ($format ? $format->($move) : undef), $game->position ];
            $game->undo_move;
        }
        $next{$position} = \@after;
        push @todo, map { $_->[1] } @after;
    }
    my $changed = 1;
    while ($changed) {
        $changed = 0;
        for my $position (keys %next) {
            next if exists $value{$position};
            my @seen = map { $value{ $_->[1] } // '' } @{ $next{$position} };
            if (grep { $_ eq 'L' } @seen) { $value{$position} = 'W'; $changed = 1 }
            elsif (!grep { $_ ne 'W' } @seen) { $value{$position} = 'L'; $changed = 1 }
        }
    }
    return (\%value, \%next);
}

1;
