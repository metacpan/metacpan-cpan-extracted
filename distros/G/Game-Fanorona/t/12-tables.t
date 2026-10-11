use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ':all';
use FnSolve qw(solve);
my $E = 'Game::Fanorona::Engine';
my $R = 'Game::Fanorona::Rules';

# THE PUBLISHED ENDGAME TABLES, WORKED OUT AGAIN THROUGH THIS ENGINE.
#
# Schadd, Winands, Uiterwijk, van den Herik and Bergsma, "Best Play in Fanorona
# Leads to Draw" (2008), Table 3, gives for every arrangement of a few stones
# on the nine by five whether the side to move wins, draws or loses with best
# play, "symmetric positions removed", a-b meaning the side to move has a
# stones:
#
#             1-1      2-1      1-2
#     Win     158   10,366      717
#     Draw    334      398    3,231
#     Loss     26        6    6,822
#
# Nothing here is told those numbers except to compare with at the end. Every
# position is made, its moves are this engine's, a game that has ended is this
# engine's ruling, and the values are found by working backwards from the
# endings: a position is won if some move reaches a position lost for the
# other side, lost if every move reaches one won for them, and a draw if
# neither is ever established.
#
# Repetition and the quiet limit are OFF: a table is about what can be forced.
# What is ON is the paper's own ruling that a side with no move has lost.
#
# TWO THINGS HAD TO BE FOUND OUT BEFORE THE THREE-STONE COLUMNS MATCHED. The
# paper's columns each sum to 10,770 and there are 10,784 arrangements. The 14
# are the ones a half turn of the board leaves unchanged (one stone on the
# centre and the other two opposite each other through it); leave those out and
# every number is the published one.

sub images {
    my ($position) = @_;
    my ($board, $side) = split / /, $position;
    my @ranks = split m{/}, $board;
    my $flat = sub { join('/', @_) . " $side" };
    my @wide = map { my $r = $_; $r =~ s/(\d)/'.' x $1/ge; $r } @ranks;
    my $pack = sub { my $r = shift; $r =~ s/(\.+)/length $1/ge; $r };
    my @mirror = map { scalar reverse $_ } @wide;
    return (
        $flat->(map { $pack->($_) } @wide),
        $flat->(map { $pack->($_) } @mirror),
        $flat->(map { $pack->($_) } reverse @wide),
        $flat->(map { $pack->($_) } reverse @mirror),
    );
}

sub positions_of {
    my ($white, $black, $side) = @_;
    my $bd = $E->new(empty => 1)->set_side($side);
    my @all = $bd->all_squares;
    my @out;
    my $place;
    $place = sub {
        my ($from, $left, $stone, $then) = @_;
        if (!$left) { $then->(); return }
        for my $i ($from .. $#all) {
            next if $bd->at($all[$i]) != EMPTY;
            $bd->put($all[$i], $stone);
            $place->($i + 1, $left - 1, $stone, $then);
            $bd->lift($all[$i]);
        }
    };
    $place->(0, $white, WHITE, sub { $place->(0, $black, BLACK, sub { push @out, $bd->to_string }) });
    return @out;
}

# The table for "the side to move has $mine stones and the other $theirs",
# White to move: orbits, and how many of each value, all of them and with the
# half-turn orbits left out.
sub table {
    my ($mine, $theirs) = @_;
    my @start = positions_of($mine, $theirs, WHITE);
    my ($value) = solve(undef, @start);
    my (%seen, %all, %kept);
    for my $position (@start) {
        my @image = images($position);
        my ($canon) = sort @image;
        next if $seen{$canon}++;
        my $v = $value->{$position} // 'D';
        $all{$v}++;
        $kept{$v}++ unless $image[3] eq $position;
    }
    return (scalar(@start), [ map { $all{$_} // 0 } qw(W D L) ], [ map { $kept{$_} // 0 } qw(W D L) ]);
}

subtest 'one stone against one' => sub {
    my ($positions, $all, $kept) = table(1, 1);
    is($positions, 1980, 'one thousand nine hundred and eighty arrangements');
    is("@$all", '158 334 26', 'win 158, draw 334, loss 26: the published column');
    is("@$kept", "@$all", 'no arrangement of two stones is unchanged by a half turn');
};

subtest 'two stones against one, the two to move' => sub {
    my ($positions, $all, $kept) = table(2, 1);
    is($positions, 42570, 'forty-two thousand five hundred and seventy arrangements');
    is("@$all", '10378 400 6', 'every orbit: win 10,378, draw 400, loss 6');
    is("@$kept", '10366 398 6', 'the half-turn orbits left out: THE PUBLISHED COLUMN');
};

# the one to move can take both in one move, and may stop after the first:
# this is the column that knows about the chain
subtest 'one stone against two, the one to move' => sub {
    my ($positions, $all, $kept) = table(1, 2);
    is($positions, 42570, 'the same number of arrangements');
    is("@$all", '717 3237 6830', 'every orbit: win 717, draw 3,237, loss 6,830');
    is("@$kept", '717 3231 6822', 'the half-turn orbits left out: THE PUBLISHED COLUMN');
};

done_testing();
