use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

my $C = $E->hole_at(0, 0);
sub at_ { my ($h, $d, $k) = @_; $h = $E->next_to($h, $d) for 1 .. ($k || 1); $h }

sub board {
    my %put = @_;
    my $bd = $E->new(seats => 2, empty => 1);
    $bd->put($_, $put{$_}) for keys %put;
    return $bd;
}

sub sorted { join ',', sort { $a <=> $b } @_ }

# ---- a lone piece reaches its steps and nothing else ------------------------------

{
    my $bd = board($C => 0);
    is(sorted($bd->reach($C)), sorted($E->neighbours($C)), 'a lone piece reaches its six neighbours');
    is(sorted($bd->reach($C)), sorted($bd->steps($C)), '  which are its steps');
}

# ---- the stop is optional -------------------------------------------------------------
#
# C, a piece on E, a gap, a piece three along: hop to two along, then on to
# four along. Both landings are stops.

{
    my $bd = board($C => 0, at_($C, E) => 1, at_($C, E, 3) => 1);
    my %r = map { $_ => 1 } $bd->reach($C);
    ok($r{ at_($C, E, 2) }, 'the first landing of a chain is a stop');
    ok($r{ at_($C, E, 4) }, 'and so is the second');
    is_deeply([ $bd->path($C, at_($C, E, 4)) ], [ $C, at_($C, E, 2), at_($C, E, 4) ], '  reached by the two hops');
    ok(!$r{ at_($C, E, 3) }, 'and the piece hopped over is not');
}

# ---- a chain that comes back to its start does not list the start --------------------

{
    my $bd = board($C => 0, at_($C, E) => 1);
    my %r = map { $_ => 1 } $bd->reach($C);
    ok($r{ at_($C, E, 2) }, 'a hop out');
    ok(!$r{$C}, 'and the hop back onto the start is not a move');
    is(scalar(my @p = $bd->path($C, $C)), 0, '  and has no path');
}

# ---- no step and no chain go to the same hole -----------------------------------------
#
# A hop moves two holes in a line and keeps the hop class; a step moves one and
# changes it. So a hole a step reaches is never one a chain reaches, and the
# "listed once, as a step" the plan provided for never happens. Every set-up and
# a thousand random boards say so.

srand 20261015;
my ($boards, $disjoint, $class_ok) = (0, 1, 1);
for my $seats (2, 3, 4, 6) {
    for my $k (0 .. 250) {
        my $bd = $k ? $E->new(seats => $seats, empty => 1) : $E->new(seats => $seats);
        if ($k) {
            my @free = 0 .. HOLES - 1;
            for my $seat (0 .. $seats - 1) {
                $bd->put(splice(@free, int rand @free, 1), $seat) for 1 .. 10;
            }
        }
        $boards++;
        for my $h (grep { defined $bd->at($_) } 0 .. HOLES - 1) {
            my %step = map { $_ => 1 } $bd->steps($h);
            for my $to ($bd->reach($h)) {
                my @p = $bd->path($h, $to);
                my $is_step = @p == 2 && grep { $_ == $to } $E->neighbours($h);
                $disjoint = 0 if !$is_step && $step{$to};
                $class_ok = 0 if $is_step == ($E->class_of($to) == $E->class_of($h));
            }
        }
    }
}
is($boards, 1004, 'every set-up and 1,000 random boards');
ok($disjoint, '  on which no hole a step reaches is reached by a chain');
ok($class_ok, '  and every step changes the hop class and every chain keeps it');

# ---- the start of a chain is empty -------------------------------------------------------
#
# Passing back through the start adds nothing, and a chain never stands next to
# its start to hop over it, because every landing is in the start's class and
# no neighbour is. So the start's emptiness cannot be seen through the reach;
# t/05-hops.t asks hops() about it directly.

{
    my $bd = board($C => 0, at_($C, E) => 1, at_($C, W) => 1);
    my %r = map { $_ => 1 } $bd->reach($C);
    ok($r{ at_($C, W, 2) } && $r{ at_($C, E, 2) }, 'hops both ways from the start');
    is_deeply([ $bd->path($C, at_($C, W, 2)) ], [ $C, at_($C, W, 2) ],
        '  and the path west is the one hop, never out east and back through the start');
}

# ---- not a piece, not a hole ---------------------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    is(scalar(my @r = $bd->reach($C)), 0, 'an empty hole has no reach');
    is(scalar(my @s = $bd->reach(121)), 0, 'nor does hole 121');
    is(scalar(my @t = $bd->path(0, 121)), 0, 'and no path goes off the star');
}

done_testing();
