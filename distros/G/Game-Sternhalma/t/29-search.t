use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Sternhalma::Engine ':all';
use SthT qw(near_home);
my $E = 'Game::Sternhalma::Engine';

my $W = { distance => 4, straggler => 2, classes => 1, blocking => 1 };

# ---- the evaluation, by hand ------------------------------------------------------------

{
    my $bd = $E->new(seats => 2, empty => 1);
    my @home = $E->point_holes(3);
    $bd->put($_, 0) for @home;
    is($bd->evaluate(0, weights => $W), -(4 * 0 + 2 * 3 + 1 * 0 + 1 * 0),
        'a full home of its own: distance 0, its rearmost piece 3 from the tip, classes right, nothing blocked');
    $bd->lift($home[0]);
    $bd->put($E->hole_at(0, 0), 0);
    my $d = $bd->distance_left(0);
    cmp_ok($bd->evaluate(0, weights => { distance => 1, straggler => 0, classes => 0, blocking => 0 }), '==', -$d,
        'with distance alone, the score is minus the distance left');
}
{
    my $s = $E->new(seats => 3)->to_string;
    my ($home) = $E->from_string($s =~ s/ 0 3 10\z/ 1 3 10;f=0/r);
    ok(defined $home, 'a three-seat board with seat 0 counted home');
    is($home->evaluate(0, weights => $W), WIN_SCORE, '  scores WIN_SCORE for seat 0');
}

# ---- the search against a brute force ------------------------------------------------------
#
# Plain minimax in Perl, from evaluate() and legal() alone, on boards with a
# few pieces, against the engine's alpha-beta with its table. The root seat
# maximises its value (its score less the best racing rival's); every other
# seat minimises it. A seat home, or the game over, is valued by place. No
# board here has a resignation, so a rival still racing is one not home.

sub value_for {
    my ($bd, $root) = @_;
    my %sc = map { $_ => $bd->evaluate($_, weights => $W) } 0 .. $bd->seats - 1;
    my @rivals = grep { $_ != $root && !$bd->finished($_) } 0 .. $bd->seats - 1;
    return $sc{$root} unless @rivals;
    my ($best) = sort { $b <=> $a } map { $sc{$_} } @rivals;
    return $sc{$root} - $best;
}

sub placed {
    my ($bd, $seat, $ply) = @_;
    my $place = $bd->place_of($seat);
    my $n = $bd->seats;
    return WIN_SCORE + ($n - $place) * 1000 - $ply if $bd->finished($seat);
    return -WIN_SCORE + ($n - $place) * 1000 + $ply;
}

my $NODES = 0;
sub minimax {
    my ($bd, $root, $depth, $ply) = @_;
    $NODES++;
    return placed($bd, $root, $ply) if $bd->over || $bd->finished($root);
    return value_for($bd, $root) if $depth == 0;
    my @moves = $bd->legal;
    @moves = ([ -1, -1 ]) unless @moves;
    my $max = $bd->to_move == $root;
    my $best;
    for my $m (@moves) {
        my ($why, $undo) = $m->[0] < 0 ? $bd->pass : $bd->play(@$m);
        my $v = minimax($bd, $root, $depth - 1, $ply + 1);
        $bd->unplay($undo);
        $best = $v if !defined $best || ($max ? $v > $best : $v < $best);
    }
    return $best;
}

sub root_value {
    my ($bd, $depth) = @_;
    my $root = $bd->to_move;
    my @moves = $bd->legal;
    @moves = ([ -1, -1 ]) unless @moves;
    my $best;
    for my $m (@moves) {
        my ($why, $undo) = $m->[0] < 0 ? $bd->pass : $bd->play(@$m);
        my $v = minimax($bd, $root, $depth - 1, 1);
        $bd->unplay($undo);
        $best = $v if !defined $best || $v > $best;
    }
    return $best;
}

srand 20261027;
my ($cases, $agree, @bad) = (0, 1);
for my $spec ([2, 3, 1], [2, 3, 2], [2, 3, 3], [3, 2, 2], [4, 2, 2]) {
    my ($seats, $per, $depth) = @$spec;
    for my $k (1 .. 12) {
        my $bd = $E->new(seats => $seats, empty => 1);
        my @free = grep { $E->point_of($_) == CENTRE || rand() < 0.3 } 0 .. HOLES - 1;
        for my $seat (0 .. $seats - 1) {
            $bd->put(splice(@free, int rand @free, 1), $seat) for 1 .. $per;
        }
        $bd->set_to_move(int rand $seats);
        my $want = root_value($bd, $depth);
        my $got = $bd->search(budget => 50_000_000, depth => $depth, seed => $k, weights => $W);
        $cases++;
        next if $got->{score} == $want;
        $agree = 0;
        push @bad, sprintf "%d seats depth %d: brute %d, search %d: %s", $seats, $depth, $want, $got->{score}, $bd->to_string if @bad < 3;
    }
}
is($cases, 60, '60 small boards: two seats at depths 1 to 3, three and four seats at depth 2');
ok($agree, '  and on every one the search\'s value is the brute force\'s') or diag join "\n", @bad;

# ---- max-n against a brute force ------------------------------------------------------------
#
# Every seat maximises its own value. A vector a node; the seat to move takes
# the child best for itself, the first such child in the search's own order
# when two tie, which the brute force cannot know, so the comparison is of the
# root seat's value, which a tie between two children best for a deeper seat
# can still move. Positions are kept where no seat below the root faces a tie.

sub maxn_vec {
    my ($bd, $depth, $ply) = @_;
    my $n = $bd->seats;
    if ($bd->over || $depth == 0) {
        return [ map { $bd->over || $bd->finished($_) ? placed($bd, $_, $ply) : value_for($bd, $_) } 0 .. $n - 1 ];
    }
    my @moves = $bd->legal;
    @moves = ([ -1, -1 ]) unless @moves;
    my $mover = $bd->to_move;
    my (@kids);
    for my $m (@moves) {
        my ($why, $undo) = $m->[0] < 0 ? $bd->pass : $bd->play(@$m);
        push @kids, maxn_vec($bd, $depth - 1, $ply + 1);
        $bd->unplay($undo);
    }
    my ($best) = sort { $b->[$mover] <=> $a->[$mover] } @kids;
    my @tied = grep { $_->[$mover] == $best->[$mover] } @kids;
    my %distinct = map { join(',', @$_) => 1 } @tied;
    $best->[$n] = 1 if keys(%distinct) > 1 || grep { defined $_->[$n] } @kids;
    return $best;
}

{
    srand 20261029;
    my ($tried, $kept, $agree) = (0, 0, 1);
    while ($kept < 15 && $tried < 400) {
        $tried++;
        my $bd = $E->new(seats => 3, empty => 1);
        my @free = grep { $E->point_of($_) == CENTRE } 0 .. HOLES - 1;
        for my $seat (0 .. 2) { $bd->put(splice(@free, int rand @free, 1), $seat) for 1 .. 2 }
        my $root = $bd->to_move;
        my @kids;
        for my $m ($bd->legal) {
            my ($why, $undo) = $bd->play(@$m);
            push @kids, maxn_vec($bd, 1, 1);
            $bd->unplay($undo);
        }
        next if grep { defined $_->[3] } @kids;
        my ($want) = sort { $b <=> $a } map { $_->[$root] } @kids;
        my $got = $bd->search(budget => 50_000_000, depth => 2, mode => SEARCH_MAXN, weights => $W);
        $kept++;
        $agree = 0 unless $got->{score} == $want;
    }
    is($kept, 15, "max-n: 15 three-seat boards with no tie below the root, of $tried tried");
    ok($agree, '  and on every one the search\'s value is the brute force\'s');
}

# a seat already home is no rival
{
    my $bd = $E->new(seats => 3, empty => 1);
    my @free = grep { $E->point_of($_) == CENTRE } 0 .. HOLES - 1;
    $bd->put(shift @free, 0) for 1 .. 3;
    $bd->put(shift @free, 1) for 1 .. 3;
    $bd->put($_, 2) for $E->point_holes(1);
    $bd->set_to_move(1);
    $bd->play(@{ ($bd->legal)[0] });
    ok($bd->finished(2), 'three seats: seat 2 fills its home, and the first move counts it home');
    my $want = root_value($bd, 2);
    is($bd->search(budget => 50_000_000, depth => 2, weights => $W)->{score}, $want,
        '  the search agrees with the brute force, with a seat home among them');
}

# ---- going home is always worth it -------------------------------------------------------------
#
# Four seats, two home already: the seat to move is one step from home. Home
# now is third place, and it must still be chosen over racing on.
{
    my ($bd, @gap) = near_home(4, 0);
    $bd->set_to_move(1);
    $bd->play($gap[1][1], $gap[1][0]);
    $bd->play($gap[2][1], $gap[2][0]);
    is_deeply([ grep { $bd->finished($_) } 0 .. 3 ], [ 1, 2 ], 'four seats, two home');
    my $s = $bd->to_move;
    is($s, 3, '  seat 3 to move, a step from home');
    for my $rung ([ 1, 1 ], [ 100_000, 0 ]) {
        my $r = $bd->search(budget => $rung->[0], depth => $rung->[1], seed => 1);
        is_deeply([ $r->{from}, $r->{to} ], [ $gap[3][1], $gap[3][0] ], "  and goes home for third place, budget $rung->[0]");
    }
}

# ---- finding the move that matters -------------------------------------------------------------

{
    my ($bd, @gap) = near_home(2, 0);
    for my $budget (1, 100, 10_000, 100_000) {
        my $r = $bd->search(budget => $budget, seed => 3);
        is_deeply([ $r->{from}, $r->{to} ], [ @{ $gap[0] }[1, 0] ], "budget $budget: the move home, one step away, is found");
    }
}

# ---- the budget ------------------------------------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    $bd->play(6, 15);
    $bd->play(114, 105);
    my $moves = () = $bd->legal;
    for my $budget (1, 50, 5_000, 50_000) {
        my $r = $bd->search(budget => $budget, seed => 1);
        cmp_ok($r->{nodes}, '<=', $budget + $moves + 1, "budget $budget: $r->{nodes} positions, within the budget and one ply over");
        cmp_ok($r->{depth}, '>=', 1, '  and the first ply always looked at whole');
    }
}

# Out of budget, the move is the best of the last depth finished, never simply
# the first in the list: on board after board, a budget of 1 plays what a
# whole one-ply look plays, and on some of them that is not legal()'s first.
{
    srand 20261028;
    my ($same, $differs) = (1, 0);
    for (1 .. 30) {
        my $bd = $E->new(seats => 2);
        for (1 .. 10 + int rand 20) {
            my @l = $bd->legal;
            $bd->play(@{ $l[ rand @l ] });
        }
        my $tiny = $bd->search(budget => 1, seed => 9);
        my $ply1 = $bd->search(budget => 50_000_000, depth => 1, seed => 9);
        $same = 0 unless $tiny->{from} == $ply1->{from} && $tiny->{to} == $ply1->{to};
        my ($first) = $bd->legal;
        $differs++ if $tiny->{from} != $first->[0] || $tiny->{to} != $first->[1];
    }
    ok($same, 'a budget of 1 plays the best move of the one ply it finished');
    cmp_ok($differs, '>', 20, "  which on $differs boards of 30 is not legal()'s first move");
}

# Cut off part way through a depth: a budget that finishes the first ply and
# runs out in the second plays the first ply's best, and says it stopped.
{
    srand 20261030;
    my ($cut, $same, $differs) = (0, 1, 0);
    for (1 .. 20) {
        my $bd = $E->new(seats => 2);
        for (1 .. 10 + int rand 20) { my @l = $bd->legal; $bd->play(@{ $l[ rand @l ] }) }
        my $one = $bd->search(budget => 50_000_000, depth => 1, seed => 5);
        my $r = $bd->search(budget => $one->{nodes} + 3, seed => 5);
        next unless $r->{stopped};
        $cut++;
        $same = 0 unless $r->{from} == $one->{from} && $r->{to} == $one->{to};
        my ($first) = $bd->legal;
        $differs++ if $r->{from} != $first->[0] || $r->{to} != $first->[1];
    }
    cmp_ok($cut, '>=', 15, "$cut searches cut off part way through the second ply");
    ok($same, '  each played the best move of the ply it finished');
    cmp_ok($differs, '>', 10, "  which on $differs of them is not legal()'s first move");
}

# A seat that must pass: the same pieces come round with the other seat to
# move, which a table that forgot the seat to move would confuse.
{
    srand 20261031;
    my ($cases, $agree) = (0, 1);
    for my $k (1 .. 10) {
        my $bd = $E->new(seats => 2, empty => 1);
        my $C = $E->hole_at(0, 0);
        $bd->put($C, 1);
        for my $d (E .. SE) {
            my $n = $E->next_to($C, $d);
            $bd->put($n, 0);
            $bd->put($E->next_to($n, $d), 0);
        }
        my @free = grep { !defined $bd->at($_) && $E->point_of($_) == CENTRE } 0 .. HOLES - 1;
        $bd->put(splice(@free, int rand @free, 1), 0) for 1 .. 1;
        $bd->set_to_move(0);
        my $want = root_value($bd, 3);
        my $got = $bd->search(budget => 50_000_000, depth => 3, seed => $k, weights => $W);
        $cases++;
        $agree = 0 unless $got->{score} == $want;
    }
    is($cases, 10, 'ten boards where seat 1 is walled in and must pass');
    ok($agree, '  and the search agrees with the brute force at depth 3 on every one');
}

# ---- the same question, the same answer --------------------------------------------------------

{
    my $bd = $E->new(seats => 4);
    my @a = map { my $r = $bd->search(budget => 20_000, seed => 4); "$r->{from}-$r->{to}" } 1 .. 3;
    my $c = $bd->clone;
    my $r = $c->search(budget => 20_000, seed => 4);
    is_deeply(\@a, [ ("$r->{from}-$r->{to}") x 3 ], 'the same board, budget and seed: the same move, on a clone too');
}

# ---- never back to an arrangement its pieces have had -------------------------------------

{
    my $bd = $E->new(seats => 2, empty => 1);
    my $C = $E->hole_at(0, 0);
    $bd->put($C, 0);
    $bd->put($E->next_to($C, E), 0);
    $bd->put(0, 1);
    my $r = $bd->search(budget => 10_000, depth => 1, seed => 1);
    my $c = $bd->clone;
    $c->play($r->{from}, $r->{to});
    my $avoided = $bd->search(budget => 10_000, depth => 1, seed => 1, avoid => [ $c->own_key(0) ]);
    ok($avoided->{from} != $r->{from} || $avoided->{to} != $r->{to},
        'a move that puts its pieces back into an arrangement they have had is not made');
    my @all;
    for my $m ($bd->legal) { my $d = $bd->clone; $d->play(@$m); push @all, $d->own_key(0) }
    my $forced = $bd->search(budget => 10_000, depth => 1, seed => 1, avoid => \@all);
    ok(defined $forced && $forced->{from} >= 0, '  unless every move does: then one is made anyway');
    my $moved = $bd->clone;
    ok($moved->do_move(0, $E->next_to(0, SE)), "seat 1's piece moved");
    is($moved->own_key(0), $bd->own_key(0), 'own_key: another seat\'s move leaves a seat\'s key alone');
    isnt($moved->key, $bd->key, '  though the board\'s key changes');
}

done_testing();
