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

sub has { my ($list, $h) = @_; scalar grep { $_ == $h } @$list }

# ---- over one piece, of either seat ------------------------------------------------------

for my $seat (0, 1) {
    my $bd = board($C => 0, at_($C, E) => $seat);
    my @h = $bd->hops($C);
    is_deeply(\@h, [ at_($C, E, 2) ], "a hop over a piece of seat $seat lands straight beyond it");
}

{
    my $bd = board($C => 0, map { (at_($C, $_) => $_ % 2) } E .. SE);
    is_deeply([ $bd->hops($C) ], [ map { at_($C, $_, 2) } E .. SE ], 'walled in by six: six hops, one each way, in direction order');
}

# ---- what is not a hop -----------------------------------------------------------------

is(scalar(my @a = board($C => 0)->hops($C)), 0, 'not over an empty hole');

{
    my $bd = board($C => 0, at_($C, E) => 1, at_($C, E, 2) => 1);
    ok(!has([ $bd->hops($C) ], at_($C, E, 3)), 'not over two pieces in a line');
    ok(!has([ $bd->hops($C) ], at_($C, E, 2)), 'not onto a piece');
    is(scalar(my @h = $bd->hops($C)), 0, 'and nothing else either');
}

{
    my $tip = 0;
    my $below = $E->next_to($tip, SE);
    my $bd = board($below => 0, $tip => 1);
    is(scalar(my @h = grep { !defined $bd->at($_) } $bd->hops($below)), 0,
        'not off the board: over the tip there is nothing to land on');
    is(scalar(my @g = $bd->hops($below)), 0, '  so no hop at all');
}

# ---- the hopped piece stays ---------------------------------------------------------------

{
    my $bd = board($C => 0, at_($C, E) => 1);
    my $to = ($bd->hops($C))[0];
    ok($bd->do_move($C, $to), 'the hop made');
    is($bd->at(at_($C, E)), 1, 'and the piece hopped over is still there');
    is($bd->count(1), 1, '  and still counted');
}

# ---- the vacated start, for a piece part way through a chain -------------------------------
#
# A piece left S, hopped over M to X. The board may still show it on S. S is
# empty for the rest of the chain: a hop may land on it, and may not go over it.

{
    my $S = $C;
    my $M = at_($S, E);
    my $X = at_($S, E, 2);
    my $bd = board($S => 0, $M => 1);
    ok(has([ $bd->hops($X, $S) ], $S), 'part way through a chain, a hop back over M lands on the start it left');
}
{
    my $S = $C;
    my $X = at_($S, E);
    my $bd = board($S => 0);
    ok(!has([ $bd->hops($X, $S) ], at_($S, W)), 'part way through a chain, a piece cannot hop over its own empty start');
    ok(has([ $bd->hops($X, -1) ], at_($S, W)), '  while a piece that did not come from there can');
    is_deeply([ $bd->hops($S) ], [ $bd->hops($S, $S) ], 'with no start given, the piece stands where it started');
}

done_testing();
