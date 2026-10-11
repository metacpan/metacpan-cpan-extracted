use strict;
use warnings;
use Test::More;

use Game::Fanorona::Engine ':all';
my $E = 'Game::Fanorona::Engine';

sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-i])([1-5])\z/ or die "not a point: $name";
    return $r * 11 + (ord($f) - ord('a') + 1);
}

# WHAT EACH BOARD SHOULD BE, written out by hand. The middle row is the big
# board's pattern carried down: a white stone directly left of the centre, a
# black one directly right, alternating outward.
my %BOARD = (
    sivy => { cols => 9, rows => 5, stones => 22, segments => 108, centre => 'e3',
              string => 'bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w' },
    dimy => { cols => 5, rows => 5, stones => 12, segments => 56,  centre => 'c3',
              string => 'bbbbb/bbbbb/bw1bw/wwwww/wwwww w' },
    telo => { cols => 3, rows => 3, stones => 4,  segments => 16,  centre => 'b2',
              string => 'bbb/w1b/www w' },
);

for my $name (sort keys %BOARD) {
    my $want = $BOARD{$name};
    subtest "the board called $name" => sub {
        my $bd = $E->new(board => $name);
        is($bd->cols, $want->{cols}, "$want->{cols} files");
        is($bd->rows, $want->{rows}, "$want->{rows} ranks");
        is($bd->points, $want->{cols} * $want->{rows}, 'and that many points');
        is(scalar($bd->all_squares), $want->{cols} * $want->{rows}, 'all_squares lists them');
        is($bd->to_string, $want->{string}, 'the set-up');
        is($bd->count(WHITE), $want->{stones}, "$want->{stones} white stones");
        is($bd->count(BLACK), $want->{stones}, "$want->{stones} black stones");
        is($bd->side, WHITE, 'White to move');
        is($bd->centre, sq($want->{centre}), "the centre is $want->{centre}");
        is($bd->at($bd->centre), EMPTY, 'and it is empty');
        ok($E->is_strong($bd->centre), 'and strong');
        is($bd->degree($bd->centre), 8, 'eight lines meet there');
        is(scalar($bd->segments), $want->{segments}, "$want->{segments} segments");
        is_deeply([ $E->size_of($name) ], [ $want->{cols}, $want->{rows} ], 'size_of names its size');

        my ($back, $err) = $E->of_string($want->{string});
        is($err, POS_OK, 'its string reads back');
        is($back->cols . 'x' . $back->rows, "$want->{cols}x$want->{rows}", 'to a board of the same size');
        is($back->key_hex, $bd->key_hex, 'with the same key');
        is($E->new(cols => $want->{cols}, rows => $want->{rows})->to_string, $want->{string},
            'and the same board is made by its cols and rows');
    };
}

subtest 'every size the engine builds' => sub {
    my @sizes = map { my $c = $_; map { [ $c, $_ ] } 3, 5 } 3, 5, 7, 9;
    is(scalar(@sizes), 8, 'eight of them');
    for my $size (@sizes) {
        my ($c, $r) = @$size;
        ok($E->size_ok($c, $r), "$c by $r is a size");
        my $bd = $E->new(cols => $c, rows => $r);
        my $stones = ($c * $r - 1) / 2;
        is($bd->count(WHITE), $stones, "$c by $r: $stones white");
        is($bd->count(BLACK), $stones, "$c by $r: $stones black");
        is($bd->at($bd->centre), EMPTY, "$c by $r: the centre is empty");
        is(scalar($bd->segments), ($c - 1) * $r + $c * ($r - 1) + ($c - 1) * ($r - 1),
            "$c by $r: a segment a step along each rank and file, and one diagonal a cell");

        # the point directly left of the centre is white and directly right is black
        is($bd->at($bd->centre - 1), WHITE, "$c by $r: white directly left of the centre");
        is($bd->at($bd->centre + 1), BLACK, "$c by $r: black directly right of it");

        # nothing of the board lies outside its own size
        my @outside = grep { $E->file_of($_) >= $c || $E->rank_of($_) >= $r }
                      map { my $rank = $_; map { $E->square_of($_, $rank) } 0 .. 8 } 0 .. 4;
        is(scalar(grep { $bd->on_board($_) } @outside), 0, "$c by $r: no point beyond its edge is on the board");
        is(scalar(grep { $bd->at($_) != BORDER } @outside), 0, "$c by $r: and each reads BORDER");
        $bd->put($_, WHITE) for @outside;
        is($bd->count(WHITE), $stones, "$c by $r: and a put there is ignored");
        my @leaks = grep { my $s = $_; grep { $bd->next_to($s, $_) >= 0 && !$bd->on_board($bd->next_to($s, $_)) } 0 .. 7 } $bd->all_squares;
        is(scalar(@leaks), 0, "$c by $r: no line leads off it");
    }

    my $wide = $E->new(cols => 5, rows => 3);
    is($wide->to_string, 'bbbbb/bw1bw/wwwww w', 'five by three: one home rank a side');
};

subtest 'a size the engine does not build' => sub {
    my @refused = ([ 4, 5 ], [ 8, 5 ], [ 11, 5 ], [ 1, 3 ], [ 9, 7 ], [ 9, 4 ], [ 9, 1 ], [ 0, 0 ], [ -3, 3 ], [ 3, -3 ]);
    my $before = $E->live;
    for my $size (@refused) {
        my ($c, $r) = @$size;
        ok(!$E->size_ok($c, $r), "$c by $r is not a size");
        ok(!eval { $E->new(cols => $c, rows => $r); 1 }, "and new croaks on it");
        like($@, qr/no board is \Q$c\E by \Q$r\E/, 'naming the size');
    }
    ok(!eval { $E->new(board => 'grande'); 1 }, 'a name that is not a board croaks');
    like($@, qr/no board is called 'grande'/, 'naming the name');
    ok(!eval { $E->new(board => 'telo', cols => 3, rows => 3); 1 }, 'a name and a size together croak');
    like($@, qr/not both/, 'saying so');
    ok(!eval { $E->new(cols => 5); 1 }, 'cols without rows croaks');
    like($@, qr/both cols and rows/, 'saying so');
    ok(!eval { $E->new(cols => 'five', rows => 5); 1 }, 'a size that is not a number croaks');
    is_deeply([ $E->size_of('grande') ], [], 'size_of answers nothing for a name that is not a board');
    is($E->live, $before, 'and nothing refused left a board behind');
};

subtest 'a point is the same number on every size' => sub {
    my $big = $E->new;
    my $small = $E->new(board => 'telo');
    is($small->centre, sq('b2'), 'b2 on the small board is the b2 of the big one');
    ok($big->on_board(sq('d1')), 'd1 is on the nine by five');
    ok(!$small->on_board(sq('d1')), 'and off the three by three');
    is($small->next_to(sq('c1'), E), -1, 'so no line leaves c1 eastward there');
    is($big->next_to(sq('c1'), E), sq('d1'), 'though one does on the big board');
    is($small->degree(sq('c3')), 3, 'c3 is a corner of the small board');
    is($big->degree(sq('c3')), 8, 'and in the open on the big one');
};

done_testing();
