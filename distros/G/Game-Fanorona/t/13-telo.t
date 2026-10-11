use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Notation qw(format_move mirror_move mirror_position);
use Game::Fanorona::Variant;
use FnSolve qw(solve);

# THE THREE BY THREE, SOLVED THROUGH THE ENGINE.
#
# Schadd et al. 2008, Table 4: "3 x 3  White". The first player wins.
#
# The set-up of the three by three is not in any text this distribution read.
# It is the nine by five's pattern carried down: the home ranks full, the
# centre empty, white directly left of the centre and black directly right.
#
#     3  b b b
#     2  w . b
#     1  w w w
#        a b c
#
# So this is two things checked at once: that set-up, and the rules, the
# chain and the stop and the ruling on a stuck side among them, on a board
# small enough for every position to be visited.
#
# plan_game_fanorona/measure/telo.py worked the same game out in Python from
# the rules text before this engine existed. Its answers are below: 1,012
# positions, White wins, and of White's four openings two win and two lose.

my $telo = Game::Fanorona::Variant->named('telo');
is($telo->start, 'bbb/w1b/www w', 'the set-up of the three by three');

my ($value, $next) = solve(\&format_move, $telo->start);

is(scalar(keys %$next), 1012, 'one thousand and twelve positions can be reached');
is($value->{ $telo->start }, 'W', 'AND WHITE, WHO MOVES FIRST, WINS: the published result');

# what each opening leaves Black facing
my %after = map { $_->[0] => ($value->{ $_->[1] } // 'D') } @{ $next->{ $telo->start } };
is_deeply(\%after, {
    'a1-b2A' => 'L',
    'a2-b2A' => 'L',
    'b1-b2A' => 'W',
    'c1-b2A' => 'W',
}, 'two openings win, a1-b2 and a2-b2, and two lose, b1-b2 and c1-b2');

my %count;
$count{ $value->{$_} // 'D' }++ for keys %$next;
is($count{W} + $count{L} + ($count{D} // 0), 1012, 'every position has a value');
cmp_ok($count{D} // 0, '>', 0, ($count{D} // 0) . ' of them are draws: a game this small still has positions nobody can force');
note("won $count{W}, lost $count{L}, drawn " . ($count{D} // 0));

# THE MIRROR IMAGE IS THE SAME GAME. The only other balanced middle rank is
# b . w, and reflecting the board maps lines to lines.
{
    my $mirror = mirror_position($telo->start, 'files');
    is($mirror, 'bbb/b1w/www w', 'the set-up reflected');
    my ($mvalue, $mnext) = solve(\&format_move, $mirror);
    is(scalar(keys %$mnext), 1012, 'the same number of positions');
    is($mvalue->{$mirror}, 'W', 'the same result');
    my %mafter = map { $_->[0] => ($mvalue->{ $_->[1] } // 'D') } @{ $mnext->{$mirror} };
    my %across = map { mirror_move($_, 'files', cols => 3, rows => 3) => $after{$_} } keys %after;
    is_deeply(\%mafter, \%across, 'and each opening, reflected, is worth what it was');
}

# THE PAPER QUOTES ONE LINE OF ITS SOLUTION: "b3-c3 would lead to a loss in 1
# because White would answer with b2-a1W-a2A". Its diagram is not readable
# here, so the position is not known; but somewhere in this game there must be
# a position with White to move in which that exact move, a withdrawal and
# then an approach, is legal and takes Black's last stones.
{
    my @found = grep {
        my $position = $_;
        / w\z/ && grep { $_->[0] eq 'b2-a1W-a2A' && $_->[1] !~ /b.* / } @{ $next->{$position} }
    } keys %$next;
    cmp_ok(scalar(@found), '>', 0, scalar(@found) . ' reachable positions in which b2-a1W-a2A wins on the spot');
    note("for one: $found[0]") if @found;
}

done_testing();
