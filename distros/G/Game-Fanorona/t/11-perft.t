use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(mtext board);
my $E = 'Game::Fanorona::Engine';

# THE GAME'S LADDER: how many sequences of N whole moves there are from the
# set-up. 5 is counted by hand in t/06-opening.t. The rest are the count of a
# second program, in another language, made from the rules text alone, and
# this engine's, which agree.
#
# It is not the step ladder of t/06 (1, 5, 17, 100, 647, 4404), where a step
# always passes the turn. Here a stone that takes may step again and the mover
# may stop, so Black has 39 replies where it had 17 steps.
subtest 'whole moves from the set-up' => sub {
    my $bd = $E->new;
    my $before = $bd->to_string;
    is_deeply([ map { $bd->perft_moves($_) } 0 .. 4 ], [ qw(1 5 39 724 18026) ], '1, 5, 39, 724, 18026');
    is($bd->to_string, $before, 'counting leaves the board as it was');
    ok(!$bd->in_chain, 'with no chain open');
    is($bd->key_hex, $bd->key_full_hex, 'and its key right');
    is($bd->count_moves, $bd->perft_moves(1), 'perft 1 is the count of moves');
};

# The same numbers by another road: list the moves in Perl, play each, recurse.
sub count_by_moves {
    my ($bd, $depth) = @_;
    return 1 unless $depth;
    my $total = 0;
    for my $m ($bd->moves) {
        my $tokens = $bd->play_move($m) or die 'a listed move would not play: ' . mtext($m);
        $total += count_by_moves($bd, $depth - 1);
        $bd->unplay_move($tokens);
    }
    return $total;
}

subtest 'perft agrees with playing the listed moves' => sub {
    my $bd = $E->new;
    is(count_by_moves($bd, 2), 39, 'thirty-nine at two');
    is(count_by_moves($bd, 3), 724, 'seven hundred and twenty-four at three');
    for my $position ('9/5wb2/2b6/3bb4/9 w', '9/1b7/3b5/w1b6/1b7 w', 'bbb/w1b/www w', 'bbbbb/bbbbb/bw1bw/wwwww/wwwww w') {
        my $small = board($position);
        is($small->perft_moves(3), count_by_moves($small, 3), "and at three from $position");
    }
};

subtest 'the smaller boards' => sub {
    # the twin's numbers
    is_deeply([ map { board('bbb/w1b/www w')->perft_moves($_) } 1 .. 4 ], [ qw(4 7 14 67) ],
        'the three by three: 4, 7, 14, 67');
    is_deeply([ map { board('bbbbb/bbbbb/bw1bw/wwwww/wwwww w')->perft_moves($_) } 1 .. 4 ], [ qw(5 21 202 3469) ],
        'the five by five: 5, 21, 202, 3469');
};

done_testing();
