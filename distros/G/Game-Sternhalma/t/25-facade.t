use strict;
use warnings;
use Test::More;

use Game::Sternhalma;
use Game::Sternhalma::Engine ':all';

# ---- whole games through play, at every seat count --------------------------------------
#
# Each seat plays the move that brings it nearest home (so seats do get home),
# with random ties. Along the way: the turn never falls to a seat that is home;
# at the end, the places and how; undone to the set-up; replayed from the log.

srand 20261026;
for my $seats (2, 3, 4, 6) {
    my $g = Game::Sternhalma->new(seats => $seats, cap => 600);
    my $start = $g->key;
    my ($turn_ok, $plays) = (1, 0);
    until ($g->over) {
        my %home = map { $_ => 1 } $g->finished;
        $turn_ok = 0 if $home{ $g->to_move };
        my $s = $g->to_move;
        my ($best, $pick);
        for my $m ($g->legal) {
            if ($m->{kind} eq 'pass') { $pick = $m; last }
            my $copy = $g->board;
            $copy->play($m->{from}, $m->{to});
            my $d = $copy->distance_left($s) + rand();
            ($best, $pick) = ($d, $m) if !defined $best || $d < $best;
        }
        my $flag = $g->play($pick->{text});
        last if defined $flag;
        $plays++;
    }
    ok($g->over, "$seats seats: the game ended, after $plays plays");
    ok($turn_ok, '  and the turn never fell to a seat already home');
    my $r = $g->result;
    isa_ok($r, 'Game::Sternhalma::Result');
    is($r->how, $g->how, '  the result says how: ' . $g->how);
    is_deeply($r->places, [ $g->places ], '  and the places: ' . join(' ', $g->places));
    is_deeply([ sort { $a <=> $b } $g->places ], [ 1 .. $seats ], '  one seat in each place') if $g->how eq 'home';
    my @home = $g->finished;
    is_deeply([ map { (($g->places)[$_]) } @home ], [ 1 .. @home ], '  the seats home took places 1, 2, ... in the order they got there');

    my @first = grep { (($g->places)[$_]) == 1 } 0 .. $seats - 1;
    is($r->winner, @first == 1 ? $first[0] : undef, '  the winner is the one seat in first place, if there is one');
    is_deeply([ $r->ranking ], [ sort { (($g->places)[$a]) <=> (($g->places)[$b]) || $a <=> $b } 0 .. $seats - 1 ],
        '  and the ranking is the seats best first');

    my $again = Game::Sternhalma->replay($g->log);
    is($again->key, $g->key, '  replayed from its log: the same position');
    is_deeply([ $again->places ], [ $g->places ], '  the same places');
    is($again->how, $g->how, '  the same ending');

    1 while $g->undo;
    is($g->key, $start, '  every play undone: the set-up key');
    is($g->ply, 0, '  ply 0');
    ok(!$g->over, '  and the game running again');
    is(scalar($g->moves), 0, '  with no moves in its log');
    is_deeply([ $g->finished ], [], '  and nobody home');
}

# ---- the first seat ---------------------------------------------------------------------------

{
    my $g = Game::Sternhalma->new(seats => 4, first => 2);
    is($g->to_move, 2, 'first => 2: seat 2 moves first');
    my ($m) = $g->legal;
    $g->play($m->{text});
    is($g->to_move, 3, '  then seat 3, clockwise');
    like($g->log, qr/^first 2$/m, '  and the log says who went first');
    is(Game::Sternhalma->replay($g->log)->key, $g->key, '  so a replay starts from the same seat');
}

# ---- a result with first place shared, as a cap or a deadlock can leave it ---------------------

{
    my $r = Game::Sternhalma::Result->new(how => 'cap', places => [ 1, 3, 1 ], ply => 40);
    ok(!defined $r->winner, 'first place shared: no winner');
    is_deeply([ $r->ranking ], [ 0, 2, 1 ], '  the ranking puts the two firsts in seat order');
    is($r->place_of(1), 3, '  place_of');
    is($r->seats, 3, '  seats');
    my $one = Game::Sternhalma::Result->new(how => 'home', places => [ 2, 1 ]);
    is($one->winner, 1, 'one seat first: the winner');
    ok(!eval { Game::Sternhalma::Result->new(how => 'tea', places => [ 1, 2 ]); 1 }, 'a way to end that is not one: refused');
    ok(!eval { Game::Sternhalma::Result->new(how => 'cap', places => [ 1, 0 ]); 1 }, 'a place of 0: refused');
    is_deeply([ Game::Sternhalma::Result->ways ], [ qw(cap deadlock home resign) ], 'the ways a game ends');
}

# ---- a game begun from a position --------------------------------------------------------------

{
    my $g = Game::Sternhalma->new(seats => 3);
    $g->play(($g->legal)[0]{text}) for 1 .. 4;
    my $from = Game::Sternhalma->new(position => $g->position);
    is($from->key, $g->key, 'a game begun from another game\'s position stands where it stood');
    is($from->ply, 4, '  four plies in');
    ok(!defined $from->first, '  and has no first seat of its own');
    $from->play(($from->legal)[0]{text}) for 1 .. 3;
    like($from->log, qr/^start /m, 'its log says where it began');
    my $again = Game::Sternhalma->replay($from->log);
    is($again->key, $from->key, '  and replays to the same position');
    is($again->ply, 7, '  seven plies in');
}

# ---- a hash, a name, and the board kept to itself ---------------------------------------------

{
    my $g = Game::Sternhalma->new;
    is($g->play({ from => 'd1', to => 'e6' }), undef, 'a move given as a hash of names');
    is($g->play({ from => 111, to => 103 }), undef, 'and as a hash of hole numbers');
    is($g->at('e6'), 0, 'at, by name');
    my $copy = $g->board;
    $copy->lift(15);
    is($g->at(15), 0, 'the board handed out is a copy: lifting from it leaves the game alone');
}

done_testing();
