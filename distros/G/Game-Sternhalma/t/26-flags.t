use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SthT qw(near_home);

use Game::Sternhalma;
use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# EVERY FLAG, FROM A REAL POSITION, AND NOTHING THROWS.

my %seen;
sub flag {
    my ($got, $want, $what) = @_;
    is($got, $want, "$what: $want");
    $seen{$want}++ if defined $want && defined $got && $got eq $want;
    ok(defined Game::Sternhalma->reason($want), '  and it has a reason in words') if defined $want;
}

{
    my $g = Game::Sternhalma->new;
    flag($g->play('e5:g5'), 'no_piece', 'a move from an empty hole');
    flag($g->play('q1-p1'), 'not_your_piece', 'a move of seat 1\'s piece on seat 0\'s turn');
    flag($g->play('c1-d1'), 'occupied', 'a move onto a piece');
    flag($g->play('d1-g5'), 'not_reachable', 'a move out of reach');
    flag($g->play('c1:e5:g5'), 'not_reachable', 'a chain whose second hop is no hop');
    flag($g->play('pass'), 'pass_not_allowed', 'a pass with moves to make');
    flag($g->play('j14-e5'), 'no_such_hole', 'a hole the star does not have');
    flag($g->play({ from => 121, to => 1 }), 'no_such_hole', '  given as a number');
    flag($g->play('hello'), 'bad_string', 'text that is not a move');
    flag($g->play('resign 4'), 'no_such_seat', 'a resignation of a seat the game does not have');
    flag($g->resign(-1), 'no_such_seat', '  through resign()');
}

{
    my $g = Game::Sternhalma->new(seats => 3);
    $g->resign(2);
    flag($g->resign(2), 'seat_resigned', 'a seat that has resigned resigns again');
}

{
    my $g = Game::Sternhalma->new;
    $g->resign(1);
    flag($g->play('d1-e6'), 'game_over', 'a move after the end');
    flag($g->resign(0), 'game_over', '  and a resignation');
}

# ---- must_pass: a seat with no move -------------------------------------------------------
#
# Three seats, ten pieces each. Seat 0 fills its start point. Seats 1 and 2
# fill the five ring holes in front of it and every hole a hop over those
# would land on; seat 2's other pieces go to the bottom point. Seat 0 has no
# step and no hop.

{
    my $bw = $E->new(seats => 3, empty => 1);
    my @start = $E->point_holes(0);
    my %start = map { $_ => 1 } @start;
    my @front = $E->front(0);
    my %front = map { $_ => 1 } @front;
    my %land;
    for my $h (@start) {
        for my $d (E .. SE) {
            my $mid = $E->next_to($h, $d);
            next unless defined $mid && $front{$mid};
            my $to = $E->next_to($mid, $d);
            $land{$to} = 1 if defined $to && !$start{$to} && !$front{$to};
        }
    }
    my @land = sort { $a <=> $b } keys %land;
    $bw->put($_, 0) for @start;
    my @one = (@front, @land);
    $bw->put($_, 1) for @one[0 .. 9];
    my @two = @one[10 .. $#one];
    push @two, grep { !defined $bw->at($_) } $E->point_holes(3);
    $bw->put($_, 2) for @two[0 .. 9];
    my ($bd, $code) = $E->from_string($bw->to_string);
    is($code, POS_OK, 'a three-seat board, ten pieces a seat, seat 0 walled into its start');
    is(scalar(my @l = $bd->legal), 0, '  seat 0 has no move');
    my $g = Game::Sternhalma->new(position => $bw->to_string);
    flag($g->play('a1-b1'), 'must_pass', 'a move by a seat with no move');
    is_deeply([ map { $_->{kind} } $g->legal ], [ 'pass' ], '  legal offers the pass alone');
    is($g->play('pass'), undef, '  and the pass is made');
}

# ---- seat_finished: a seat home cannot resign ------------------------------------------------

{
    my ($bn, @gap) = near_home(3, 0);
    my $g = Game::Sternhalma->new(position => $bn->to_string);
    is($g->play({ from => $gap[0][1], to => $gap[0][0] }), undef, 'seat 0 steps home');
    is_deeply([ $g->finished ], [ 0 ], '  and is home');
    flag($g->resign(0), 'seat_finished', 'a seat home resigns');
}

# ---- nothing throws ----------------------------------------------------------------------

{
    my $g = Game::Sternhalma->new;
    my @weird = (undef, 42, 3.5, {}, [], sub {}, \'x', 'x' x 10_000, '', ' ', "d1-e6\n", { from => [], to => {} },
                 { kind => 'resign', seat => 'x' }, { kind => 'jump' }, -1);
    my $lived = 1;
    for my $w (@weird) {
        my $flag = eval { $g->play($w) };
        $lived = 0 if $@ || !defined $flag;
    }
    ok($lived, 'play lived through fifteen things that are not moves, and refused every one');
    is($g->ply, 0, '  and none of them was made');
    my $lived2 = !!eval { $g->resign($_) for undef, 'x', [], 99; 1 };
    ok($lived2, 'and resign lived through four things that are not seats');
}

is_deeply([ sort keys %seen ], [ sort keys %Game::Sternhalma::REASON ],
    'every one of the ' . scalar(keys %Game::Sternhalma::REASON) . ' flags reached from a real position');

done_testing();
