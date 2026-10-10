use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

=pod

HOW MANY POSITIONS A RULE SET HAS, two ways that share nothing.

The engine walks every one, cell by cell. This file computes the number: a
side has some squares only it visits and some both sides visit, and a position
is a choice of which of each hold whose piece, times the ways to split what is
left between hand and home, times two for the side to move.

    short route: six squares a side of its own, eight shared
    long route:  four squares a side of its own, twelve shared

Those four numbers are typed here from the board and not asked of the engine.

For the short route with seven pieces the answer is 275,827,872, and that is
also the number a third party published for the game they solved (RoyalUr.net,
"How we solved the Royal Game of Ur", read 9 October 2026: "a map of
275,827,872 unique positions", and 137,913,936 for one side to move). Their
"over a billion positions" for the long route is 1,002,065,904 here.

=cut

sub choose {
    my ($n, $k) = @_;
    return 0 if $k < 0 || $k > $n;
    my $c = 1;
    $c = $c * ($n - $_ + 1) / $_ for 1 .. $k;
    return $c;
}

sub computed {
    my ($own, $shared, $pieces) = @_;
    my $total = 0;
    for my $i (0 .. $own) {
        for my $j (0 .. $own) {
            for my $a (0 .. $shared) {
                for my $b (0 .. $shared - $a) {
                    next if $i + $a > $pieces || $j + $b > $pieces;
                    $total += choose($own, $i) * choose($own, $j)
                            * choose($shared, $a) * choose($shared - $a, $b)
                            * ($pieces - $i - $a + 1) * ($pieces - $j - $b + 1);
                }
            }
        }
    }
    return 2 * $total;
}

my %SQUARES = (short => [ 6, 8 ], long => [ 4, 12 ]);

subtest 'the squares a side has to itself, and the squares both visit' => sub {
    my %route = (short => ROUTE_SHORT, long => ROUTE_LONG);
    for my $name (sort keys %SQUARES) {
        my $shared = grep { $E->route_shared($route{$name}, $_) } $E->all_cells;
        is($shared, $SQUARES{$name}[1], "$name: $SQUARES{$name}[1] shared");
        is((20 - $shared) / 2, $SQUARES{$name}[0], "and $SQUARES{$name}[0] a side of its own");
    }
};

subtest 'walked and computed agree, one to seven pieces, both routes' => sub {
    for my $name (sort keys %SQUARES) {
        for my $pieces (1 .. 7) {
            my $walked = $E->count_positions({ route => $name, pieces => $pieces });
            my $want   = computed(@{ $SQUARES{$name} }, $pieces);
            is($walked, sprintf('%.0f', $want), "$name route, $pieces a side: $walked");
        }
    }
};

# WRITTEN DOWN, so that neither the walk nor the formula can drift together.
subtest 'the numbers themselves' => sub {
    is($E->count_positions({ pieces => 1 }), '496', 'one piece a side, short route');
    is($E->count_positions({ route => 'long', pieces => 1 }), '624', 'and long');
    is($E->count_positions('finkel'),  '275827872',  'finkel: the published number');
    is($E->count_positions('masters'), '1002065904', 'masters: over a billion');
    is($E->count_positions(undef), $E->count_positions('finkel'), 'no rule set is finkel');
    like($E->count_positions('masters'), qr/\A[0-9]+\z/, 'a string of digits, whatever this perl can hold');
};

subtest 'what does not change the count' => sub {
    my $finkel = $E->count_positions('finkel');
    is($E->count_positions({ safe_rosettes => 0 }), $finkel, 'whether a rosette is safe');
    is($E->count_positions({ dice => 3, zero_rolls => 4 }), $finkel, 'nor the dice');
    isnt($E->count_positions({ route => 'long' }), $finkel, 'the route does');
    isnt($E->count_positions({ pieces => 6 }), $finkel, 'and so does the number of pieces');
};

done_testing();
