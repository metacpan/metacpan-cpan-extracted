use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ':all';
use FnT qw(mtext);
my $R = 'Game::Fanorona::Rules';

# WHOLE GAMES, PLAYED BY THE TWIN. t/games.txt was written by a second program,
# in another language, from the rules text alone: each row a game from its
# first position to its end, with how it ended. Here every move of every game
# is put through Game::Fanorona::Rules. The game must accept each move, must
# not be over before the last, and must end exactly there, the way the twin
# says, with the same winner, counts and final position.

open my $fh, '<', "$FindBin::Bin/games.txt" or die "t/games.txt: $!";
my ($games, $moves, %how, @bad) = (0, 0);
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /\A#/ || $line !~ /\S/;
    my ($quiet, $repeat, $cap, $start, $how, $winner, $plies, $quiet_at_end, $final, $list) = split /\t/, $line, -1;
    my $game = $R->new(position => $start, variant => { quiet_limit => $quiet, repeat => $repeat, ply_cap => $cap });
    $games++;
    my $label = "game $games ($start)";
    my @played = split ' ', $list;
    my $fault;
    for my $i (0 .. $#played) {
        if ($game->over) { $fault = "over after $i moves, by " . $game->how . ", with moves still to play"; last }
        my ($move) = grep { mtext($_) eq $played[$i] } $game->moves;
        if (!$move) { $fault = "move " . ($i + 1) . ", $played[$i], is not a move of " . $game->position; last }
        if (!$game->play_move($move)) { $fault = "move " . ($i + 1) . ", $played[$i], was refused"; last }
        $moves++;
    }
    if (!$fault) {
        my $won = $game->winner == WHITE ? 'w' : $game->winner == BLACK ? 'b' : '-';
        $fault = 'not over at the end' unless $game->over;
        $fault //= 'ended by ' . $game->how . ", the twin says $how" unless $game->how eq $how;
        $fault //= "won by $won, the twin says $winner" unless $won eq $winner;
        $fault //= 'ply ' . $game->ply . ", the twin says $plies" unless $game->ply == $plies;
        $fault //= 'quiet ' . $game->quiet . ", the twin says $quiet_at_end" unless $game->quiet == $quiet_at_end;
        $fault //= 'final position ' . $game->position . ", the twin says $final" unless $game->position eq $final;
    }
    if (!$fault) {
        # and the whole game comes back
        1 while $game->undo;
        $fault = 'undone, it is not at its first position' unless $game->position eq $start && $game->ply == 0;
        $fault //= 'undone, it is still over' if $game->over && @played;
    }
    push @bad, "$label: $fault" if $fault;
    $how{$how}++;
}
is($games, 170, 'one hundred and seventy games read');
cmp_ok($moves, '>', 2000, "$moves moves played through the game");
cmp_ok($how{stones} // 0, '>', 100, ($how{stones} // 0) . ' ended with a side out of stones');
cmp_ok($how{$_} // 0, '>=', 1, ($how{$_} // 0) . " ended by $_") for qw(repetition quiet ply_cap);
is(scalar(@bad), 0, 'and every game is the twin\'s game, move for move and ending for ending')
    or diag join "\n", @bad[0 .. ($#bad < 3 ? $#bad : 3)];

done_testing();
