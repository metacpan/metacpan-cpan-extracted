use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

ok($E->tables_ok, 'the tables were built and every count in the header agreed');
is($E->squares, 81, 'eighty-one squares');

# ---- the numbering ------------------------------------------------------------------
#
# SFEN order: rank a first, file 9 first in each rank. Every expectation below
# is worked from the file and the rank, never read back from the engine.

sub sq_of { my ($f, $r) = @_; ($r - 1) * 9 + (9 - $f) }

my %fixed = ('9a' => 0, '1a' => 8, '9b' => 9, '5e' => 40, '7g' => 56, '1i' => 80, '9i' => 72);
is($E->square($_), $fixed{$_}, "$_ is square $fixed{$_}") for sort keys %fixed;

my $names_ok = 1;
for my $f (1 .. 9) {
    for my $r (1 .. 9) {
        my $sq = sq_of($f, $r);
        my $name = $f . chr(ord('a') + $r - 1);
        $names_ok = 0 unless $E->square($name) == $sq
            && $E->square_name($sq) eq $name
            && $E->file_of($sq) == $f
            && $E->rank_of($sq) == $r
            && $E->sq_of($f, $r) == $sq;
    }
}
ok($names_ok, 'all 81: the name, the number, the file, the rank and sq_of agree');

is($E->square($_), undef, "'" . ($_ // 'undef') . "' is not a square")
    for '0a', '9j', '10a', '7G', 'g7', '', ' 7g', undef;
is($E->square_name($_), undef, ($_ // 'undef') . ' has no name') for -1, 81, 'x', undef;
is($E->sq_of(@$_), undef, "($_->[0], $_->[1]) is off the board") for [0, 1], [10, 1], [1, 0], [1, 10];

# ---- the step through the mailbox ---------------------------------------------------
#
# Every step the mailbox serves, from every square, against the arithmetic.
# The knight's two ranks from the edge ranks is what a margin too narrow gets
# wrong, so it is counted on its own.

my ($steps, $off, $bad, $knight_off) = (0, 0, 0, 0);
for my $sq (0 .. 80) {
    my ($f, $r) = ($E->file_of($sq), $E->rank_of($sq));
    for my $df (-1 .. 1) {
        for my $dr (-2 .. 2) {
            my ($tf, $tr) = ($f + $df, $r + $dr);
            my $want = ($tf >= 1 && $tf <= 9 && $tr >= 1 && $tr <= 9) ? sq_of($tf, $tr) : undef;
            my $got = $E->step($sq, $df, $dr);
            $steps++;
            $off++ unless defined $want;
            $knight_off++ if !defined $want && abs($dr) == 2 && $df != 0;
            $bad++ if (defined $got) != (defined $want) || (defined $got && $got != $want);
        }
    }
}
is($bad, 0, "$steps steps from every square match the arithmetic");
cmp_ok($knight_off, '>', 0, "$knight_off knight jumps fall off the board, and every one says so");

is($E->square_name($E->step($E->square('7g'), 0, -1)), '7f', 'from 7g, a rank towards a is 7f: forward for Black');
is($E->square_name($E->step($E->square('7g'), 1, 0)), '8g', 'and a file up is 8g');
is($E->square_name($E->step($E->square('2h'), -1, -2)), '1f', 'a knight-shaped step from 2h reaches 1f');
is($E->step($E->square('9a'), 0, -1), undef, 'nothing is above rank a');
is($E->step($E->square('1i'), -1, 0), undef, 'nothing is right of file 1');
is($E->step($E->square('5e'), $_->[0], $_->[1]), undef, "a step of ($_->[0], $_->[1]) is wider than any piece's and is refused")
    for [2, 0], [-2, 0], [0, 3], [0, -3], [2, 2];
is($E->step($_, 0, 0), undef, "no step from '" . ($_ // 'undef') . "'") for -1, 81, 'a', undef;

# ---- the zone and the distance to the last rank -------------------------------------

my %zone;
my ($zone_ok, $last_ok) = (1, 1);
for my $sq (0 .. 80) {
    my $r = $E->rank_of($sq);
    for my $side (qw(b w)) {
        my $want = $side eq 'b' ? $r <= 3 : $r >= 7;
        $zone{$side}++ if $E->in_zone($side, $sq);
        $zone_ok = 0 if !!$E->in_zone($side, $sq) != !!$want;
        $last_ok = 0 unless $E->last_distance($side, $sq) == ($side eq 'b' ? $r - 1 : 9 - $r);
    }
}
ok($zone_ok, "Black's zone is ranks a to c and White's g to i");
is_deeply(\%zone, { b => 27, w => 27 }, 'twenty-seven squares each');
ok($last_ok, 'the distance to the last rank is 0 on the furthest rank and 8 on the back rank, for each side');
is($E->last_distance('b', $E->square('3a')), 0, "rank a is Black's last rank");
is($E->last_distance('w', $E->square('3i')), 0, "rank i is White's");
is($E->in_zone('x', 0), 0, 'a side that is not b or w has no zone');
is($E->last_distance('b', 81), undef, 'and a square that is not one has no distance');

# ---- the kinds ----------------------------------------------------------------------

my %promotes = (P => '+P', L => '+L', N => '+N', S => '+S', B => '+B', R => '+R',
                p => '+p', r => '+r');
is($E->promoted($_), $promotes{$_}, "$_ promotes to $promotes{$_}") for sort keys %promotes;
is($E->promoted($_), undef, "$_ does not promote") for qw(G K g k +P +r X), '';
is($E->unpromoted($_->[0]), $_->[1], "$_->[0] is a $_->[1] underneath")
    for ['+P', 'P'], ['+r', 'r'], ['+B', 'B'], ['S', 'S'], ['k', 'k'];
is($E->unpromoted($_), undef, "'$_' is not a piece") for '+G', '+K', 'X', '';

is_deeply([ map { Game::Shogi::Engine::_promoted($_) } 0 .. 15 ],
    [ 0, TOKIN, PRO_LANCE, PRO_KNIGHT, PRO_SILVER, 0, HORSE, DRAGON, 0, 0, 0, 0, 0, 0, 0, 0 ],
    'by number: the pawn, lance, knight, silver, bishop and rook promote, and nothing else');
is_deeply([ map { Game::Shogi::Engine::_unpromoted($_) } 0 .. 15 ],
    [ 0, PAWN, LANCE, KNIGHT, SILVER, GOLD, BISHOP, ROOK, KING,
      PAWN, LANCE, KNIGHT, SILVER, BISHOP, ROOK, 0 ],
    'and each promoted kind turns back into its own base kind');

my %set = (P => 18, L => 4, N => 4, S => 4, G => 4, B => 2, R => 2, K => 2);
is($E->set_count($_), $set{$_}, "a set has $set{$_} of $_") for sort keys %set;
my $total = 0;
$total += $E->set_count($_) for keys %set;
is($total, SET_PIECES, 'forty in all');
is($E->set_count('+P'), 0, 'a promoted piece is not a kind a set counts');

done_testing();
