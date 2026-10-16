use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

my $centre = $E->hole_at(0, 0);
my @tips = grep { $E->degree($_) == 2 } 0 .. HOLES - 1;

# ---- on an empty board a step is every neighbour ------------------------------------

{
    my $bd = $E->new(seats => 2, empty => 1);
    for my $t (@tips) {
        $bd->put($t, 0);
        is(scalar(my @s = $bd->steps($t)), 2, "a piece on tip $t has two steps");
        $bd->lift($t);
    }
    $bd->put($centre, 0);
    is_deeply([ sort { $a <=> $b } $bd->steps($centre) ], [ sort { $a <=> $b } $E->neighbours($centre) ],
        'a piece in the middle of an empty board steps to all six neighbours');
    my $all_ok = 1;
    for my $h (0 .. HOLES - 1) {
        my $c = $bd->clone;
        $c->lift($centre);
        $c->put($h, 0);
        my @s = sort { $a <=> $b } $c->steps($h);
        $all_ok = 0 unless "@s" eq join ' ', sort { $a <=> $b } $E->neighbours($h);
    }
    ok($all_ok, 'and so does a lone piece on every one of the 121 holes');
    is_deeply([ $bd->steps($centre) ], [ map { $E->next_to($centre, $_) } E .. SE ], 'the steps come in direction order');
}

# ---- a step does not go onto a piece, of either seat -----------------------------------

{
    my $bd = $E->new(seats => 2, empty => 1);
    $bd->put($centre, 0);
    $bd->put($E->next_to($centre, E), 0);
    $bd->put($E->next_to($centre, NW), 1);
    my %s = map { $_ => 1 } $bd->steps($centre);
    ok(!$s{ $E->next_to($centre, E) }, 'no step onto a piece of the same seat');
    ok(!$s{ $E->next_to($centre, NW) }, 'no step onto a rival');
    is(scalar(keys %s), 4, 'and the four empty neighbours are steps');
}

# ---- the set-up, counted by hand -------------------------------------------------------
#
# Seat 0's front row is row 3, four holes at x = 1 to 4. Each has two neighbours
# in row 4, SW and SE, both empty; every other neighbour of every piece is a
# piece. So 8 steps, onto five holes of row 4.
#
# AND SIX HOPS, which the first count by hand missed and the engine did not:
# row 2 is three holes at x = 2 to 4, and each hops SW and SE over the front row
# into row 4, landing at x = 0 to 4. The twin agrees (t/07-twin.t).

{
    my $bd = $E->new(seats => 2);
    my (@pairs, %to);
    for my $h (grep { defined $bd->at($_) && $bd->at($_) == 0 } 0 .. HOLES - 1) {
        for my $t ($bd->steps($h)) {
            push @pairs, "$h-$t";
            $to{$t}++;
        }
    }
    is(scalar(@pairs), 8, 'the two-seat set-up: seat 0 has 8 steps');
    is_deeply([ sort { $a <=> $b } keys %to ], [ map { $E->hole_at($_, -4) } 0 .. 4 ],
        '  onto the five holes of row 4 in front of it');
    is_deeply([ sort { $a <=> $b } map { $E->row_of((split /-/)[0]) } @pairs ], [ (3) x 8 ],
        '  all from the front row');
    my (@hops, %hop_to);
    for my $h (grep { defined $bd->at($_) && $bd->at($_) == 0 } 0 .. HOLES - 1) {
        for my $t ($bd->hops($h)) {
            push @hops, $h;
            $hop_to{$t}++;
        }
    }
    is(scalar(@hops), 6, 'seat 0 has 6 hops');
    is_deeply([ sort { $a <=> $b } map { $E->row_of($_) } @hops ], [ (2) x 6 ], '  all from the second row');
    is_deeply([ sort { $a <=> $b } keys %hop_to ], [ map { $E->hole_at($_, -4) } 0 .. 4 ],
        '  over the front row onto row 4');
    my $all = 0;
    $all += scalar(my @h = $bd->hops($_)) for 0 .. HOLES - 1;
    is($all, 12, 'and twelve hops for the two seats together');
}

# ---- holes and boards that are not there ------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    is(scalar(my @s = $bd->steps(121)), 0, 'hole 121 has no steps');
    is(scalar(my @t = $bd->steps(-1)), 0, 'nor -1');
    is(scalar(my @u = $bd->steps('x')), 0, 'nor a word');
}

done_testing();
