use strict;
use warnings;
use Test::More;

use Game::Sternhalma;
use Game::Sternhalma::Bot;
use Game::Sternhalma::Engine ':all';

is_deeply([ Game::Sternhalma::Bot->rungs ], [ 0, 1, 2, 3 ], 'four rungs, weakest first');

# ---- every rung plays only legal moves, at every seat count ----------------------------
#
# Rungs 0 to 2 play whole games; rung 3 plays the first 30 plies of a game,
# which is where it is slow.

for my $seats (2, 3, 4, 6) {
    for my $rung (0 .. 3) {
        my $g = Game::Sternhalma->new(seats => $seats);
        my ($legal_ok, $plies) = (1, 0);
        while (!$g->over && ($rung < 3 || $plies < 30)) {
            my $move = Game::Sternhalma::Bot->choose($g, rung => $rung, seed => 7);
            my $flag = $g->play($move);
            $legal_ok = 0, last if defined $flag;
            $plies++;
        }
        ok($legal_ok, "$seats seats, rung $rung: $plies plies, every move legal" . ($g->over ? ', to the end' : ''));
    }
}

# ---- the same game, rung and seed: the same move -------------------------------------------

{
    my $g = Game::Sternhalma->new(seats => 3);
    $g->play(Game::Sternhalma::Bot->choose($g, rung => 1, seed => 1)) for 1 .. 8;
    for my $rung (0 .. 3) {
        my @m = map { my $m = Game::Sternhalma::Bot->choose($g, rung => $rung, seed => 11); "$m->{from}-$m->{to}" } 1 .. 2;
        my $e = Game::Sternhalma::Bot->choose($g->board, rung => $rung, seed => 11, history => [ $g->history($g->to_move) ]);
        is_deeply([ @m, "$e->{from}-$e->{to}" ], [ ($m[0]) x 3 ], "rung $rung: the same move twice, and from the engine with the history");
    }
    my $t = Game::Sternhalma::Bot->think($g, rung => 2, seed => 11);
    cmp_ok($t->{nodes}, '>', 0, 'think says what the choice cost: ' . $t->{nodes} . ' positions');
    is($t->{rung}, 2, '  and at which rung');
}

# ---- the seed settles ties, so seeds differ; rung 0 goes forward ----------------------------

{
    my %moves;
    my $g = Game::Sternhalma->new(seats => 2);
    for my $seed (1 .. 20) {
        my $m = Game::Sternhalma::Bot->choose($g, rung => 1, seed => $seed);
        $moves{"$m->{from}-$m->{to}"}++;
    }
    cmp_ok(scalar(keys %moves), '>', 1, 'twenty seeds at the set-up give ' . scalar(keys %moves) . ' different moves at rung 1: ties are the seed\'s');
    my $forward = 1;
    for my $seed (1 .. 20) {
        my $copy = $g->board;
        my $m = Game::Sternhalma::Bot->choose($g, rung => 0, seed => $seed);
        my $before = $copy->distance_left(0);
        $copy->play($m->{from}, $m->{to});
        $forward = 0 unless $copy->distance_left(0) < $before;
    }
    ok($forward, 'rung 0 at the set-up always takes a piece nearer home');
}

# ---- rung 0 goes forward in the middle of a game too -------------------------------------

{
    srand 20261032;
    my ($tried, $forward) = (0, 0);
    for (1 .. 40) {
        my $g = Game::Sternhalma->new(seats => 3);
        $g->play(Game::Sternhalma::Bot->choose($g, rung => 1, seed => $_)) for 1 .. 6 + int rand 30;
        next if $g->over;
        my $bb = $g->board;
        my $seat = $bb->to_move;
        my $home = ($bb->layout_point(3, $seat) + 3) % 6;
        my ($tip) = grep { $bb->degree($_) == 2 } $bb->point_holes($home);
        my $d = sub { my ($x1, $y1) = $bb->xy($_[0]); my ($x2, $y2) = $bb->xy($tip); my ($dx, $dy) = ($x1 - $x2, $y1 - $y2);
                      my @a = map { abs } $dx, $dy, -$dx - $dy; (sort { $b <=> $a } @a)[0] };
        my $any = grep { $d->($_->[1]) < $d->($_->[0]) } $bb->legal;
        next unless $any;
        my $m = Game::Sternhalma::Bot->choose($g, rung => 0, seed => $_);
        $tried++;
        $forward++ if $d->($m->{to}) < $d->($m->{from});
    }
    cmp_ok($tried, '>=', 30, "$tried positions in the middle of three-seat games with a move forward");
    is($forward, $tried, '  and rung 0 went forward in every one');
}

# ---- the bot does not put its pieces back as they were -------------------------------------
#
# Seat 0 has nine pieces home and its last at the top, with a ladder of seat
# 1's pieces straight down to its home: its best move by far is the chain
# down. The game begins with that piece already at the bottom; seat 0 hops it
# back up, seat 1 shuffles inside its own home, and now the chain down would
# put seat 0's pieces back as they began. A search told nothing takes it; the
# bot, reading the game's history, does not.
#
# Built rather than waited for: after 07's fixes to the evaluation, two-seat
# games at rung 2 never met the case in six whole games, so the history is a
# guard that seldom binds, and only a built position can test it.

{
    my $E = 'Game::Sternhalma::Engine';
    my $copy = $E->new(seats => 2, empty => 1);
    my @ladder = map { $E->hole_at(0, $_) } -3, -1, 1, 3;
    my ($X, $Z) = ($E->hole_at(0, -4), $E->hole_at(0, 4));
    my @home0 = $E->point_holes(3);
    my ($gap) = grep { !grep { $_ == $Z } $E->neighbours($_) } @home0;
    $copy->put($_, 0) for grep { $_ != $gap } @home0;
    $copy->put($Z, 0);
    $copy->put($_, 1) for @ladder;
    my @top = $E->point_holes(0);
    $copy->put($_, 1) for @top[0 .. 5];
    my $g = Game::Sternhalma->new(position => $copy->to_string);
    ok($g, 'a two-seat board, ten pieces each, the last piece of seat 0 at the bottom of a ladder');
    is($g->play({ from => $Z, to => $X }), undef, 'seat 0 hops it back to the top');
    my $shuffle = (grep { my ($f, $t2) = @$_; (grep { $_ == $f } @top) && (grep { $_ == $t2 } @top) } $g->board->legal)[0];
    ok($shuffle, 'seat 1 has a move inside its own home');
    is($g->play({ from => $shuffle->[0], to => $shuffle->[1] }), undef, '  and makes it');
    my $back = sub { my ($m) = @_; return 0 if $m->{pass}; my $c = $g->board; $c->play($m->{from}, $m->{to}); $c->own_key(0) eq ($g->history(0))[0] };
    my $raw = $g->board->search(budget => 10_000, seed => 3);
    ok($back->($raw), '  a search told nothing takes the chain down, putting seat 0\'s pieces back as they began');
    my $bot = Game::Sternhalma::Bot->think($g, rung => 2, seed => 3);
    ok(!$back->($bot), '  the bot, reading the history, does not');
}

# ---- a game that is over, and a rung that is not there ---------------------------------------

{
    my $g = Game::Sternhalma->new;
    $g->resign(1);
    ok(!defined Game::Sternhalma::Bot->choose($g), 'no move once the game is over');
    ok(!eval { Game::Sternhalma::Bot->choose(Game::Sternhalma->new, rung => 9); 1 }, 'a rung that is not there is refused');
    like($@, qr/no rung 9; there are 0, 1, 2, 3/, '  naming the rungs there are');
    ok(!eval { Game::Sternhalma::Bot->choose('x'); 1 }, 'and so is something that is not a game');
}

done_testing();
