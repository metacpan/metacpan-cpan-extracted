use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
use Game::Sternhalma::Notation qw(format_game parse_game);
my $E = 'Game::Sternhalma::Engine';

# A GAME IS ITS SEATS, ITS PIECES, ITS CAP AND ITS MOVES AS TEXT. Not the paths,
# which the position gives back; not the keys, which replay gives back. Each
# game is played at random, written out, read back, and replayed on a fresh
# board, and must give the same key at every ply and the same places at the end.

srand 20261024;
my ($games, $plies, $keys_ok, $end_ok, %how) = (0, 0, 1, 1);
for my $seats (2, 3, 4, 6) {
    for my $k (1 .. 125) {
        my $pieces = $seats <= 3 && $k % 5 == 0 ? 15 : 10;
        my $bd = $E->new(seats => $seats, pieces => $pieces);
        $bd->set_cap(40 + int rand 120);
        my (@moves, @keys);
        while (!$bd->over) {
            my $text;
            if (rand() < 0.005 && $seats > 2) {
                my $s = int rand $seats;
                my ($why) = $bd->resign($s);
                next unless $why == PLAY_OK;
                $text = "resign $s";
            }
            elsif ($bd->can_pass) { $bd->pass; $text = 'pass' }
            else {
                my @l = $bd->legal;
                my $m = $l[ rand @l ];
                $text = $bd->move_text(@$m);
                $bd->play(@$m);
            }
            push @moves, $text;
            push @keys, $bd->key;
        }
        my $log = format_game({ seats => $seats, pieces => $pieces, cap => $bd->cap, moves => \@moves });
        my ($g, $why) = parse_game($log);
        unless ($g) { $keys_ok = 0; diag $why; next }
        my $re = $E->new(seats => $g->{seats}, pieces => $g->{pieces});
        $re->set_cap($g->{cap});
        for my $i (0 .. $#{ $g->{moves} }) {
            my ($m, $err) = $re->read_move($g->{moves}[$i]);
            my ($ok) = !$m ? (1) : $m->{kind} eq 'pass' ? $re->pass
                     : $m->{kind} eq 'resign' ? $re->resign($m->{seat})
                     : $re->play($m->{from}, $m->{to});
            $keys_ok = 0 unless $m && $ok == PLAY_OK && $re->key eq $keys[$i];
            $plies++;
        }
        $end_ok = 0 unless $re->over && $re->how == $bd->how && join(',', $re->places) eq join(',', $bd->places)
            && $re->to_string eq $bd->to_string;
        $how{ $bd->how }++;
        $games++;
    }
}
# ---- greedy games, which get home ------------------------------------------------------------
#
# Random players never get anyone home, so these play greedily (the move that
# brings the mover nearest home), and are logged and replayed the same way.

for my $seats (2, 3) {
    for my $k (1 .. 10) {
        my $bd = $E->new(seats => $seats);
        my (@moves, @keys);
        while (!$bd->over) {
            my $s = $bd->to_move;
            my ($best, $at);
            for my $m ($bd->legal) {
                my $c = $bd->clone;
                $c->play(@$m);
                my $d = $c->distance_left($s) + rand();
                ($best, $at) = ($d, $m) if !defined $best || $d < $best;
            }
            if ($at) { push @moves, $bd->move_text(@$at); $bd->play(@$at) }
            else { push @moves, 'pass'; $bd->pass }
            push @keys, $bd->key;
        }
        my ($g) = parse_game(format_game({ seats => $seats, pieces => 10, moves => \@moves }));
        my $re = $E->new(seats => $seats);
        for my $i (0 .. $#moves) {
            my ($m) = $re->read_move($g->{moves}[$i]);
            my ($ok) = $m->{kind} eq 'pass' ? $re->pass : $re->play($m->{from}, $m->{to});
            $keys_ok = 0 unless $ok == PLAY_OK && $re->key eq $keys[$i];
            $plies++;
        }
        $end_ok = 0 unless $re->how == $bd->how && join(',', $re->places) eq join(',', $bd->places);
        $how{ $bd->how }++;
        $games++;
    }
}

is($games, 520, '500 random games, 125 at each seat count, some of fifteen pieces, and 20 greedy ones');
cmp_ok($plies, '>', 30_000, "$plies plies replayed from text");
ok($keys_ok, 'every ply replayed to the key it had');
ok($end_ok, 'every game ended the same way, in the same places, on the same position');
ok($how{ (BY_CAP) } && $how{ (BY_RESIGN) } && $how{ (BY_HOME) }, 'among them games ended by the cap, by resigning, and by getting home ('
    . join(', ', map { "$_: $how{$_}" } sort keys %how) . ')');

done_testing();
