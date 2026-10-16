#!perl
use strict;
use warnings;
use Test::More;

# D's depth 5, the first ply with drops in it: 2,776 of them. About a second and
# a half on the dev box, longer on a smoker, so it is an author test.
# plan_game_shogi/perft-talkchess-duhamel-2016-06-12.txt.
#
# Depth 6 (547,581,517) was matched once by hand, in every column, on 15 Oct
# 2026: see plan_game_shogi/03-the-drops.md. Set SHOGI_PERFT_6=1 to run it here
# (about forty seconds).

use Game::Shogi::Engine;
my $E = 'Game::Shogi::Engine';

my @D = (
    [ 5, 19861490,  113680,  2776,   57214,   71434,   0 ],
    [ 6, 547581517, 3387051, 393476, 1588324, 1730177, 0 ],
);

for my $d (@D) {
    my ($depth, @want) = @$d;
    next if $depth == 6 && !$ENV{SHOGI_PERFT_6};
    my $c = $E->new->perft_counts($depth);
    is_deeply([ @$c{qw(nodes captures drops promotions checks mates)} ], \@want,
        "D depth $depth: nodes $want[0], captures $want[1], drops $want[2], promotions $want[3], checks $want[4], mates $want[5]");
}

done_testing();
