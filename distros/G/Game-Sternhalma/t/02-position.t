use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

my $live0 = $E->live;

# ---- the set-ups, written out -------------------------------------------------------

my %SETUP = (
    '2x10' => '0/00/000/0000/[13]/[12]/[11]/[10]/[9]/[10]/[11]/[12]/[13]/1111/111/11/1 0 2 10',
    '3x10' => '0/00/000/0000/[13]/[12]/[11]/[10]/[9]/2[8]1/22[7]11/222[6]111/2222[5]1111/[4]/[3]/[2]/[1] 0 3 10',
    '4x10' => '0/00/000/0000/[9]1111/[9]111/[9]11/[9]1/[9]/3[9]/33[9]/333[9]/3333[9]/2222/222/22/2 0 4 10',
    '6x10' => '0/00/000/0000/5555[5]1111/555[6]111/55[7]11/5[8]1/[9]/4[8]2/44[7]22/444[6]222/4444[5]2222/3333/333/33/3 0 6 10',
    '2x15' => '0/00/000/0000/[4]00000[4]/[12]/[11]/[10]/[9]/[10]/[11]/[12]/[4]11111[4]/1111/111/11/1 0 2 15',
    '3x15' => '0/00/000/0000/[4]00000[4]/[12]/[11]/[10]/2[7]1/22[6]11/222[5]111/2222[4]1111/22222[3]11111/[4]/[3]/[2]/[1] 0 3 15',
);

# PINNED. Changing the zobrist generator, its seed or its fill order moves
# every one of these, and that must be a red test.
my %KEY = (
    '2x10' => '0ed8aa3a59f80586',
    '3x10' => 'd0791ed4a31a1673',
    '4x10' => 'ebbd926714f7c76b',
    '6x10' => '2ab49995cbb77d85',
);

my %LAYOUT = (2 => [0, 3], 3 => [0, 2, 4], 4 => [0, 1, 3, 4], 6 => [0 .. 5]);

for my $name (sort keys %SETUP) {
    my ($seats, $pieces) = split /x/, $name;
    my $copy = $E->new(seats => $seats, pieces => $pieces);
    is($copy->to_string, $SETUP{$name}, "$seats seats of $pieces: the set-up string");
    is($copy->key, $KEY{$name}, "$seats seats of $pieces: the pinned key") if $KEY{$name};
    is($copy->to_move, 0, "$seats seats of $pieces: seat 0 to move");
    is_deeply([ map { $copy->seat_point($_) } 0 .. $seats - 1 ], $LAYOUT{$seats}, "$seats seats: the points, clockwise from the top");
    my $placed_ok = 1;
    for my $seat (0 .. $seats - 1) {
        my $p = $LAYOUT{$seats}[$seat];
        my @start = $E->point_holes($p);
        push @start, $E->front($p) if $pieces == 15;
        my %start = map { $_ => 1 } @start;
        $placed_ok = 0 unless $copy->count($seat) == $pieces;
        $placed_ok = 0 if grep { !defined $copy->at($_) || $copy->at($_) != $seat } @start;
        $placed_ok = 0 if grep { !$start{$_} && defined $copy->at($_) && $copy->at($_) == $seat } 0 .. HOLES - 1;
    }
    ok($placed_ok, "$seats seats of $pieces: every seat fills its start and nothing else");

    my ($back, $code) = $E->from_string($SETUP{$name});
    is($code, POS_OK, "$seats seats of $pieces: the string reads back");
    is($back->key, $copy->key, "$seats seats of $pieces: to the same key");
}

is_deeply([ map { $E->layout_point($_->[0], $_->[1]) // 'undef' } [2, 2], [3, -1], [5, 0], [7, 0], [1, 0] ],
    [ 'undef', 'undef', 'undef', 'undef', 0 ], 'no seat 2 in two, no seat -1, no five or seven seats; one seat starts at the top');

# ---- what is built and what is refused ---------------------------------------------

my %built = map { $_ => 1 } qw(1x10 2x10 3x10 4x10 6x10 1x15 2x15 3x15);
for my $seats (0 .. 7) {
    for my $pieces (9, 10, 12, 15, 16) {
        my $want = $built{"${seats}x$pieces"} ? 1 : 0;
        next if $want == $E->layout_ok($seats, $pieces);
        fail("layout_ok($seats, $pieces) should be $want");
    }
}
pass('layout_ok: 2, 3, 4 and 6 seats of 10, and 1 to 3 seats of 15, and nothing else');

for my $bad ([5, 10], [7, 10], [0, 10], [4, 15], [6, 15], [2, 12], ['two', 10]) {
    my ($s, $p) = @$bad;
    ok(!eval { $E->new(seats => $s, pieces => $p); 1 }, "new refuses $s seats of $p pieces");
    like($@, qr/no game is \Q$s\E seats of \Q$p\E pieces/, '  and says so');
}

# ---- the key -----------------------------------------------------------------------

{
    my $copy = $E->new(seats => 2);
    my $start = $copy->key;
    $copy->set_to_move(1);
    isnt($copy->key, $start, 'the key names the seat to move');
    $copy->set_to_move(0);
    is($copy->key, $start, '  and comes back when the turn does');

    my $hole = ($E->point_holes(0))[0];
    $copy->put($hole, 1);
    isnt($copy->key, $start, 'the key names which seat a piece is');
    is($copy->count(0), 9, '  a put over another seat takes its piece out of the count');
    is($copy->count(1), 11, '  and puts the new one in');
    $copy->put($hole, 0);
    is($copy->key, $start, '  and comes back when the piece does');

    my $empty = 60;
    $copy->put($empty, 0);
    $copy->lift($empty);
    is($copy->key, $start, 'put then lift leaves the key as it was');
    $copy->lift($empty);
    is($copy->key, $start, 'lifting an empty hole changes nothing');

    $copy->put($empty, 2);
    $copy->put(121, 0);
    $copy->set_to_move(2);
    is($copy->key, $start, 'a seat the board does not have, and a hole it does not have, are ignored');

    isnt($E->new(seats => 2, empty => 1)->key, $E->new(seats => 3, empty => 1)->key,
        'the key names the seat count: two empty boards of different counts differ');
}

{
    my $copy = $E->new(seats => 3);
    my $c = $copy->clone;
    is($c->key, $copy->key, 'a clone has the same key');
    $c->lift(0);
    is($copy->at(0), 0, '  and is a board of its own: lifting from it leaves the original');
    is($c->at(0), undef, '  while the clone has the hole empty');
}

# ---- round trips ---------------------------------------------------------------------

srand 20261014;
my ($trips, $trip_ok) = (0, 1);
for my $seats (2, 3, 4, 6) {
    for my $pieces (10, 15) {
        next unless $E->layout_ok($seats, $pieces);
        for (1 .. 500) {
            my $copy = $E->new(seats => $seats, pieces => $pieces, empty => 1);
            my @free = 0 .. HOLES - 1;
            for my $seat (0 .. $seats - 1) {
                for (1 .. $pieces) {
                    my $h = splice @free, int(rand @free), 1;
                    $copy->put($h, $seat);
                }
            }
            $copy->set_to_move(int rand $seats);
            my $s = $copy->to_string;
            my ($back, $code) = $E->from_string($s);
            $trips++;
            $trip_ok = 0 unless $code == POS_OK && $back->to_string eq $s && $back->key eq $copy->key;
        }
    }
}
is($trips, 3000, '3,000 random positions written');
ok($trip_ok, '  and every one read back to the same string and key');

# ---- refusals, each with its reason, in the order they are asked ---------------------

my $two = $SETUP{'2x10'};
(my $no_fields = $two) =~ s/ .*//;
my @REFUSED = (
    [ POS_NULL,   '',                                         'an empty string' ],
    [ POS_NULL,   undef,                                      'no string' ],
    [ POS_LONG,   '0' x 600,                                  'a string of 600' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/^0/a/; $s },       'a letter' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/^0/6/; $s },       'a seat 6' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/\[9\]/[0]/; $s },  'a run of 0' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/\[9\]/[14]/; $s }, 'a run of 14' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/\[9\]/[09]/; $s }, 'a run with a leading zero' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/\[9\]/[9/; $s },   'a run not closed' ],
    [ POS_LETTER, do { (my $s = $two) =~ s/^0\//a\/\//; $s }, 'a letter AND eighteen rows: the letter is asked first' ],
    [ POS_ROWS,   do { (my $s = $two) =~ s/^0\///; $s },      'sixteen rows' ],
    [ POS_ROWS,   do { (my $s = $two) =~ s/^0\//0\/\//; $s }, 'eighteen rows' ],
    [ POS_WIDTH,  do { (my $s = $two) =~ s/\[13\]/[12]/; $s }, 'a row of 13 written as 12' ],
    [ POS_WIDTH,  do { (my $s = $two) =~ s/\[13\]/[12]00/; $s }, 'a row of 13 written as 14, which would run past the board' ],
    [ POS_WIDTH,  do { (my $s = $two) =~ s/^0\/00/00\/0/; $s }, 'the first two rows of the wrong lengths' ],
    [ POS_FIELDS, $no_fields,                                 'no fields at all' ],
    [ POS_FIELDS, "$no_fields 0 2",                            'no piece count' ],
    [ POS_FIELDS, "$no_fields 0 7 10",                         'seven seats' ],
    [ POS_FIELDS, "$no_fields 0 5 10",                         'five seats' ],
    [ POS_FIELDS, "$no_fields 2 2 10",                         'seat 2 to move in a two-seat game' ],
    [ POS_FIELDS, "$no_fields 0 2 12",                         'twelve pieces' ],
    [ POS_FIELDS, "$no_fields 0 4 15",                         'fifteen pieces at four seats' ],
    [ POS_FIELDS, "$no_fields 0 2 10 ",                        'a space after the fields' ],
    [ POS_FIELDS, "$no_fields  0 2 10",                        'two spaces' ],
    [ POS_SEAT,   do { (my $s = $two) =~ s/^0\/00/2\/00/; $s }, 'a piece of seat 2 in a two-seat game' ],
    [ POS_COUNT,  do { (my $s = $two) =~ s/^0\//[1]\//; $s },  'seat 0 with nine pieces' ],
    [ POS_COUNT,  "$no_fields 0 3 10",                         'three seats with seat 2 nowhere' ],
);
for my $r (@REFUSED) {
    my ($want, $string, $what) = @$r;
    my ($copy, $code) = $E->from_string($string);
    is($code, $want, "refused, code $want: $what");
    ok(!defined $copy, '  and no board');
}
like($E->reason(POS_COUNT), qr/exactly/, 'a code has a reason in words');
ok(!eval { $E->new(position => 'x'); 1 }, 'new(position => ...) croaks on a refused string');
like($@, qr/refused: the position has a character/, '  with the reason');

# ---- the pointer is the class's own ---------------------------------------------------

{
    my $before = $E->live;
    ok(!eval { $E->new(_ptr => 12345); 1 }, 'new(_ptr => N) is refused');
    like($@, qr/a board is made by new, from_string or clone/, '  and says how a board is made');
    is($E->live, $before, '  and makes no board');
    ok(!$E->can('_ptr') || !eval { $E->new(seats => 2)->_ptr; 1 },
        'the address cannot be read from outside the class');
}

{
    my $before = $E->live;
    {
        my $copy = $E->new(seats => 6);
        my $c = $copy->clone;
        my ($d) = $E->from_string($copy->to_string);
        is($E->live, $before + 3, 'three boards made');
    }
    is($E->live, $before, 'and all three let go when their objects went');
}

is($E->live, $live0, 'no board leaked in this file');

done_testing();
