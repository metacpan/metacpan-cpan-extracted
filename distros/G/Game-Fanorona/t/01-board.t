use strict;
use warnings;
use Test::More;

use Game::Fanorona::Engine ':all';
my $E = 'Game::Fanorona::Engine';

# A point by its name. WRITTEN HERE AND NOT BORROWED FROM THE ENGINE: the
# arithmetic is the header's, typed out a second time, so a stride that moved
# would disagree with this and not with itself.
sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-i])([1-5])\z/ or die "not a point: $name";
    return $r * 11 + (ord($f) - ord('a') + 1);
}

sub name_of {
    my ($s) = @_;
    return chr(ord('a') + ($s % 11) - 1) . int($s / 11);
}

my @FILES = ('a' .. 'i');
my @NAMES = map { my $r = $_; map { "$_$r" } @FILES } 1 .. 5;

# THE LINES, WORKED OUT A SECOND TIME. A point is joined along its rank and its
# file, and diagonally when its file and rank add to an even number. This is
# the rule in the plan's own words and shares no code with fn_engine.c.
my @STEP = ([0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]);
sub model_next {
    my ($cols, $rows, $f, $r, $dir) = @_;
    my ($df, $dr) = @{ $STEP[$dir] };
    return -1 if $df && $dr && ($f + $r) % 2;
    my ($tf, $tr) = ($f + $df, $r + $dr);
    return -1 if $tf < 0 || $tf >= $cols || $tr < 0 || $tr >= $rows;
    return ($tr + 1) * 11 + ($tf + 1);
}

subtest 'the set-up is the diagram' => sub {
    my $bd = $E->new;
    is($bd->count(WHITE), 22, 'twenty-two white stones');
    is($bd->count(BLACK), 22, 'twenty-two black stones');
    is($bd->side, WHITE, 'White moves first');
    is($bd->cols, 9, 'nine files');
    is($bd->rows, 5, 'five ranks');
    is($bd->points, 45, 'forty-five points');
    is($bd->centre, sq('e3'), 'the centre is e3');
    is($bd->at(sq('e3')), EMPTY, 'and it is empty');

    # every one of the forty-five, named, so a stone on the wrong side of the
    # middle row cannot hide behind a count that still adds up. The middle row
    # is the Commons diagram's: b w b w . b w b w.
    my %want = (
        (map { ("${_}1" => WHITE, "${_}2" => WHITE, "${_}4" => BLACK, "${_}5" => BLACK) } @FILES),
        a3 => BLACK, b3 => WHITE, c3 => BLACK, d3 => WHITE, e3 => EMPTY,
        f3 => BLACK, g3 => WHITE, h3 => BLACK, i3 => WHITE,
    );
    is(scalar(keys %want), 45, 'the expectation names forty-five points');
    my @wrong = grep { $bd->at(sq($_)) != $want{$_} } @NAMES;
    is("@wrong", '', 'all forty-five points hold what the diagram shows');

    # the paper's own two openings need these three exactly
    is($bd->at(sq('d3')), WHITE, 'd3 is white: d3-e3 is a move of White');
    is($bd->at(sq('f3')), BLACK, 'f3 is black: it is what d3-e3 approaches');
    is($bd->at(sq('c3')), BLACK, 'c3 is black: it is what d3-e3 withdraws from');
};

subtest 'a point is a padded index' => sub {
    my (%seen, @bad);
    for my $r (0 .. 4) {
        for my $f (0 .. 8) {
            my $s = $E->square_of($f, $r);
            push @bad, "($f,$r) gave $s" unless $s == ($r + 1) * 11 + ($f + 1);
            push @bad, "($f,$r) does not come apart"
                unless $E->file_of($s) == $f && $E->rank_of($s) == $r;
            $seen{$s}++;
        }
    }
    is("@bad", '', 'square_of, file_of and rank_of agree for all forty-five');
    is(scalar(keys %seen), 45, 'forty-five distinct points');
    is($E->stride, 11, 'the stride is 11');

    my $bd = $E->new;
    is_deeply([ $bd->all_squares ], [ map { sq($_) } @NAMES ], 'all_squares is a1 to i5, rank by rank');

    is($E->square_of(9, 0), -1, 'file 9 is not a file');
    is($E->square_of(0, 5), -1, 'rank 5 is not a rank');
    is($E->square_of(-1, 0), -1, 'nor is a negative file');
    is($E->file_of(0), -1, 'cell 0 is in the ring and has no file');
    is($E->rank_of(11), -1, 'the cell left of a1 has no rank');
    is($E->file_of(77), -1, 'and a cell past the grid has neither');

    my @ring = grep { !$seen{$_} } 0 .. 76;
    is(scalar(@ring), 32, 'thirty-two cells of the grid are the ring');
    my @open = grep { $bd->at($_) != BORDER } @ring, -1, 77, 1000;
    is("@open", '', 'and every one of them, and anything outside, reads BORDER');
    my @inside = grep { $bd->on_board($_) } @ring, -1, 77;
    is("@inside", '', 'on_board is false for all of them');
};

subtest 'strong and weak' => sub {
    my @strong = grep { $E->is_strong(sq($_)) } @NAMES;
    is(scalar(@strong), 23, 'twenty-three strong points');
    is(45 - @strong, 22, 'twenty-two weak ones');

    # the paper: "a weak intersection at e2 and a strong intersection at e3"
    ok($E->is_strong(sq('e3')), 'e3 is strong');
    ok(!$E->is_strong(sq('e2')), 'e2 is weak');
    ok($E->is_strong(sq('a1')), 'a1 is strong');
    ok(!$E->is_strong(sq('b1')), 'b1 is weak');
    ok($E->is_strong(sq('i5')), 'i5 is strong');

    my @wrong = grep {
        my ($f, $r) = (ord(substr($_, 0, 1)) - ord('a'), substr($_, 1) - 1);
        !!$E->is_strong(sq($_)) != !(($f + $r) % 2)
    } @NAMES;
    is("@wrong", '', 'a point is strong exactly when its file and rank add to an even number');
    ok(!$E->is_strong(0), 'a cell of the ring is not strong');
};

subtest 'the lines' => sub {
    my $bd = $E->new;
    my @bad;
    for my $r (0 .. 4) {
        for my $f (0 .. 8) {
            for my $dir (0 .. 7) {
                my $s = ($r + 1) * 11 + ($f + 1);
                my $got = $bd->next_to($s, $dir);
                my $want = model_next(9, 5, $f, $r, $dir);
                push @bad, name_of($s) . " dir $dir: $got, wanted $want" unless $got == $want;
            }
        }
    }
    is("@bad", '', 'next_to agrees with the rule written out again, at all 360 point-directions');

    is($bd->degree(sq('a1')), 3, 'a1 has three lines');
    is($bd->degree(sq('e3')), 8, 'e3 has eight');
    is($bd->degree(sq('e2')), 4, 'e2 has four');
    is($bd->degree(sq('a2')), 3, 'a2 has three');
    is($bd->degree(sq('e1')), 5, 'e1 has five');
    is($bd->degree(sq('i5')), 3, 'i5 has three');
    is($bd->degree(0), 0, 'and a cell of the ring has none');

    is_deeply([ map { name_of($_) } $bd->neighbours(sq('e3')) ], [ qw(e4 f4 f3 f2 e2 d2 d3 d4) ],
        'the neighbours of e3, clockwise from north');
    is_deeply([ map { name_of($_) } $bd->neighbours(sq('e2')) ], [ qw(e3 f2 e1 d2) ],
        'the neighbours of e2: no diagonal');
    is_deeply([ map { name_of($_) } $bd->neighbours(sq('a1')) ], [ qw(a2 b2 b1) ],
        'the neighbours of a1');

    is($bd->next_to(sq('e2'), NE), -1, 'no diagonal leaves a weak point');
    is($bd->next_to(sq('i3'), E), -1, 'no line leaves the edge');
    is($bd->next_to(sq('e3'), 8), -1, 'direction 8 is not a direction');
    is($bd->next_to(sq('e3'), -1), -1, 'nor is -1');
    is($bd->next_to(0, N), -1, 'and nothing leaves the ring');

    my (@from_weak, @into_weak, @one_way);
    for my $name (@NAMES) {
        for my $dir (0 .. 7) {
            my $to = $bd->next_to(sq($name), $dir);
            next if $to < 0;
            push @one_way, "$name dir $dir" unless $bd->next_to($to, $E->opposite($dir)) == sq($name);
            next unless $E->is_diagonal($dir);
            push @from_weak, $name unless $E->is_strong(sq($name));
            push @into_weak, "$name to " . name_of($to) unless $E->is_strong($to);
        }
    }
    is("@from_weak", '', 'no diagonal starts at a weak point');
    is("@into_weak", '', 'no diagonal ends at a weak point');
    is("@one_way", '', 'every line can be walked back the way it came');
};

subtest 'directions' => sub {
    is_deeply([ N, NE, E, SE, S, SW, W, NW ], [ 0 .. 7 ], 'clockwise from north, 0 to 7');
    is_deeply([ map { $E->opposite($_) } 0 .. 7 ], [ 4, 5, 6, 7, 0, 1, 2, 3 ], 'the opposite of each');
    is($E->opposite(8), -1, 'and of nothing');
    is_deeply([ map { $E->is_diagonal($_) ? 1 : 0 } 0 .. 7 ], [ 0, 1, 0, 1, 0, 1, 0, 1 ], 'the odd ones are the diagonals');

    my $bd = $E->new;
    is($bd->next_to(sq('e3'), N),  sq('e4'), 'north is up the board, towards Black');
    is($bd->next_to(sq('e3'), E),  sq('f3'), 'east is towards the i file');
    is($bd->next_to(sq('e3'), SW), sq('d2'), 'south-west is down and left');
    is($bd->next_to(sq('e3'), NW), sq('d4'), 'north-west is up and left');
};

subtest 'the segments' => sub {
    my $bd = $E->new;
    my @seg = $bd->segments;
    is(scalar(@seg), 108, 'one hundred and eight');

    my (%seen, @unordered, $flat, $upright, $slant);
    for my $pair (@seg) {
        my ($from, $to) = @$pair;
        push @unordered, "$from,$to" unless $from < $to;
        $seen{"$from,$to"}++;
        my $df = abs(($from % 11) - ($to % 11));
        my $dr = abs(int($from / 11) - int($to / 11));
        if    ($df == 1 && $dr == 0) { $flat++ }
        elsif ($df == 0 && $dr == 1) { $upright++ }
        elsif ($df == 1 && $dr == 1) { $slant++ }
    }
    is("@unordered", '', 'each has its lower point first');
    is(scalar(keys %seen), 108, 'and no two are the same');
    is($flat, 40, 'forty along the ranks');
    is($upright, 36, 'thirty-six up the files');
    is($slant, 32, 'thirty-two diagonals, one in each unit cell');

    # the same set, from the model and not from the engine
    my %model;
    for my $r (0 .. 4) {
        for my $f (0 .. 8) {
            my $s = ($r + 1) * 11 + ($f + 1);
            for my $dir (0 .. 7) {
                my $to = model_next(9, 5, $f, $r, $dir);
                next if $to < 0;
                my ($lo, $hi) = $s < $to ? ($s, $to) : ($to, $s);
                $model{"$lo,$hi"} = 1;
            }
        }
    }
    is_deeply([ sort keys %seen ], [ sort keys %model ], 'they are the joined pairs of the rule, no more and no fewer');

    # THE FOUR SYMMETRIES OF THE RECTANGLE map the lines onto themselves. A
    # diagonal drawn the wrong way in one corner breaks exactly this.
    my %mirror = (
        'left to right' => sub { my ($f, $r) = @_; (8 - $f, $r) },
        'top to bottom' => sub { my ($f, $r) = @_; ($f, 4 - $r) },
        'half a turn'   => sub { my ($f, $r) = @_; (8 - $f, 4 - $r) },
    );
    for my $how (sort keys %mirror) {
        my %image;
        for my $key (keys %seen) {
            my @ends = map {
                my ($f, $r) = $mirror{$how}->(($_ % 11) - 1, int($_ / 11) - 1);
                ($r + 1) * 11 + ($f + 1);
            } split /,/, $key;
            my ($lo, $hi) = sort { $a <=> $b } @ends;
            $image{"$lo,$hi"} = 1;
        }
        is_deeply([ sort keys %image ], [ sort keys %seen ], "mirrored $how, the lines are the same lines");
    }
};

subtest 'put and lift judge nothing' => sub {
    my $bd = $E->new(empty => 1);
    is($bd->count(WHITE) + $bd->count(BLACK), 0, 'an empty board has no stones');
    is($bd->side, WHITE, 'and White is to move');
    is($bd->to_string, '9/9/9/9/9 w', 'its string is five empty ranks');

    is(ref($bd->put(sq('e3'), WHITE)), $E, 'put returns the board');
    is($bd->at(sq('e3')), WHITE, 'a stone where it was put');
    is($bd->count(WHITE), 1, 'counted');
    $bd->put(sq('e3'), BLACK);
    is($bd->at(sq('e3')), BLACK, 'a second put replaces the first');
    is($bd->count(WHITE), 0, 'the white stone is no longer counted');
    is($bd->count(BLACK), 1, 'the black one is');
    is(ref($bd->lift(sq('e3'))), $E, 'lift returns the board');
    is($bd->at(sq('e3')), EMPTY, 'and the point is empty');
    is($bd->count(BLACK), 0, 'and nothing is counted');
    $bd->lift(sq('e3'));
    is($bd->count(BLACK), 0, 'lifting an empty point takes nothing off the count');

    $bd->put($_, WHITE) for $bd->all_squares;
    is($bd->count(WHITE), 45, 'forty-five white stones is a board put will make');

    $bd->put(0, BLACK)->put(-5, BLACK)->put(77, BLACK)->put(sq('e3'), BORDER)->put(sq('e3'), 9);
    is($bd->count(BLACK), 0, 'a put off the board is ignored');
    is($bd->at(sq('e3')), WHITE, 'and so is a put of something that is not a stone');

    is(ref($bd->set_side(BLACK)), $E, 'set_side returns the board');
    is($bd->side, BLACK, 'and the side is set');
    $bd->set_side(7);
    is($bd->side, BLACK, 'a side that is not a side is ignored');
    is(other(WHITE), BLACK, 'other(WHITE)');
    is(other(BLACK), WHITE, 'other(BLACK)');
};

subtest 'a board is made and dropped exactly once' => sub {
    my $before = $E->live;
    {
        my $bd = $E->new;
        is($E->live, $before + 1, 'new makes one');
        my $copy = $bd->clone;
        is($E->live, $before + 2, 'clone makes another');
        $copy->lift(sq('a1'))->set_side(BLACK);
        is($bd->at(sq('a1')), WHITE, 'a change to the clone does not reach the original');
        is($bd->side, WHITE, 'nor does its side');
        is($copy->count(WHITE), 21, 'and the clone did change');
        my ($parsed) = $E->of_string('bbb/w1b/www w');
        is($E->live, $before + 3, 'of_string makes a third');
    }
    is($E->live, $before, 'and all three are dropped when they go out of scope');

    # THE ADDRESS IS NOT A CONSTRUCTOR ARGUMENT. An object built round a number
    # somebody passed in would free that number when it was destroyed.
    my $made = eval { $E->new(_ptr => 12345) };
    like($@, qr/a board is made by new, of_string or clone/, 'new(_ptr => N) croaks');
    is($made, undef, 'and hands nothing back');
    is($E->live, $before, 'and no board was made or dropped by trying');
    ok(!eval { $E->new->_ptr; 1 }, 'the address cannot be read from outside the class');
};

done_testing();
