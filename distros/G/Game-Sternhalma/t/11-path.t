use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# Hops from `from` counted layer by layer: the fewest hops to each landing.
sub depths {
    my ($bd, $from) = @_;
    my %depth = ($from => 0);
    my @layer = ($from);
    for (my $d = 1; @layer; $d++) {
        my @next;
        for my $at (@layer) {
            for my $land ($bd->hops($at, $from)) {
                next if exists $depth{$land};
                $depth{$land} = $d;
                push @next, $land;
            }
        }
        @layer = @next;
    }
    return \%depth;
}

srand 20261017;
my ($moves, $chains, $legal_ok, $shortest_ok, $longest) = (0, 0, 1, 1, 0);
my @bad;
for my $seats (2, 3, 4, 6) {
    for my $k (1 .. 60) {
        my $bd = $E->new(seats => $seats, empty => 1);
        my @free = 0 .. HOLES - 1;
        for my $seat (0 .. $seats - 1) {
            $bd->put(splice(@free, int rand @free, 1), $seat) for 1 .. 10;
        }
        $bd->set_to_move(int rand $seats);
        for my $m ($bd->legal) {
            my ($from, $to) = @$m;
            my @p = $bd->path($from, $to);
            $moves++;
            my $ok = @p >= 2 && $p[0] == $from && $p[-1] == $to;
            my $step = @p == 2 && grep { $_ == $to } $E->neighbours($from);
            unless ($step) {
                for my $i (1 .. $#p) {
                    $ok = 0 unless grep { $_ == $p[$i] } $bd->hops($p[ $i - 1 ], $from);
                }
                my %seen;
                $ok = 0 if grep { $seen{$_}++ } @p;
                $chains++;
                $shortest_ok = 0 unless @p - 1 == depths($bd, $from)->{$to};
                $longest = @p if @p > $longest;
            }
            $legal_ok = 0 unless $ok;
            push @bad, $bd->to_string . " $from-$to: @p" if !$ok && @bad < 3;
        }
    }
}
cmp_ok($moves, '>', 10_000, "$moves moves on 240 random boards");
cmp_ok($chains, '>', 3_000, "$chains of them chains");
ok($legal_ok, 'every path runs from its start to its stop, each hop a hop, no hole twice; a step is two neighbours')
    or diag join "\n", @bad;
ok($shortest_ok, 'and every chain is as short as the fewest hops to its stop');
cmp_ok($longest, '<=', PATH_MAX, "the longest path seen, $longest holes, is within PATH_MAX");

# ---- the same position gives the same path, however it was reached --------------------

{
    my $bd = $E->new(seats => 2);
    my $history = $E->new(seats => 2);
    my @moves = ([ 6, 15 ], [ 111, 104 ], [ 3, 16 ], [ 117, 103 ]);
    for my $m (@moves) {
        $bd->do_move(@$m);
    }
    $history->do_move(@$_) for reverse @moves;
    is($history->to_string, $bd->to_string, 'the same four moves made in the other order reach the same position');
    my ($fresh) = $E->from_string($bd->to_string);
    my $same = 1;
    for my $m ($bd->legal) {
        my $shown = join ',', $bd->path(@$m);
        $same = 0 unless $shown eq join(',', $fresh->path(@$m)) && $shown eq join(',', $bd->clone->path(@$m))
            && $shown eq join(',', $history->path(@$m));
    }
    ok($same, 'and it, its clone, a board read from its string and the other history show every move by the same path');
}

# ---- what has no path --------------------------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    my $C = $E->hole_at(0, 0);
    is(scalar(my @a = $bd->path($C, 14)), 0, 'no path from an empty hole');
    is(scalar(my @b = $bd->path(6, $C)), 0, 'no path to a hole out of reach');
    is(scalar(my @c = $bd->path(6, 6)), 0, 'no path from a hole to itself');
    is(scalar(my @d = $bd->path(6, 7)), 0, 'no path onto a piece');
}

done_testing();
