use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype);

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# THE GRID, TYPED OUT. A test that asked the engine where each house is drawn and
# then checked the engine agreed would pass for any answer. This is C's
# numbering, plan_game_senet/00-overview.md "The board".
my @GRID = (
    [  1,  2,  3,  4,  5,  6,  7,  8,  9, 10 ],
    [ 20, 19, 18, 17, 16, 15, 14, 13, 12, 11 ],
    [ 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 ],
);
my @MARKED = (15, 26, 27, 28, 29, 30);

subtest 'the grid, house by house' => sub {
    is(HOUSES, 30, 'HOUSES is thirty');
    my @bad;
    for my $row (0 .. 2) {
        for my $col (0 .. 9) {
            my $want = $GRID[$row][$col];
            my $got  = $E->house_of($row, $col);
            push @bad, "($row,$col) is $got, not $want" unless $got == $want;
            push @bad, "$want comes apart as (" . $E->row_of($want) . ',' . $E->col_of($want) . ')'
                unless $E->row_of($want) == $row && $E->col_of($want) == $col;
        }
    }
    is("@bad", '', 'house_of, row_of and col_of agree with the grid for all thirty');
    is_deeply([ $E->all_houses ], [ 1 .. 30 ], 'all_houses is 1 to 30');

    is($E->house_of(3, 0),  -1, 'row 3 is not on the board');
    is($E->house_of(-1, 0), -1, 'nor is row -1');
    is($E->house_of(0, 10), -1, 'column 10 is not on the board');
    is($E->house_of(0, -1), -1, 'nor is column -1');
    is($E->row_of(0),  -1, 'house 0 has no row');
    is($E->row_of(31), -1, 'nor does house 31');
    is($E->col_of(0),  -1, 'house 0 has no column');
    is($E->col_of(31), -1, 'nor does house 31');
};

subtest 'the track turns at the ends of the rows' => sub {
    is($E->row_of(10), 0, 'house 10 ends the top row');
    is($E->row_of(11), 1, 'house 11 begins the middle row');
    is($E->col_of(10), $E->col_of(11), 'and stands directly below 10');
    is($E->row_of(20), 1, 'house 20 ends the middle row');
    is($E->col_of(20), $E->col_of(21), 'and 21 stands directly below it');
    is($E->col_of(1), $E->col_of(20),
        'houses 1 and 20 share a column, though the track puts eighteen houses between them');
};

subtest 'the marked houses' => sub {
    my @marked = grep { $E->is_marked($_) } 0 .. 31;
    is("@marked", "@MARKED", 'exactly 15 and 26 to 30 are marked');
    is_deeply([ $E->marked_houses ], \@MARKED, 'and marked_houses lists the same six');
    is(REBIRTH, 15, 'REBIRTH is house 15');
};

subtest 'an empty board' => sub {
    my $bd = $E->new;
    my @full = grep { $bd->at($_) != EMPTY } $E->all_houses;
    is("@full", '', 'all thirty houses read EMPTY');
    is($bd->side, SIDE_LIGHT, 'light is to move');
    is($bd->pieces, 5, 'five pieces a side unless told');
    is($bd->count(SIDE_LIGHT), 0, 'none of light on the board');
    is($bd->count(SIDE_DARK),  0, 'none of dark');
    is($bd->home(SIDE_LIGHT), 5, 'so all five of light are home');
    is($bd->home(SIDE_DARK),  5, 'and all five of dark');
    is($bd->ply, 0, 'at ply 0');
    is($bd->at(0),  -1, 'house 0 is not a house');
    is($bd->at(31), -1, 'nor is house 31');
    is($bd->at(-1), -1, 'nor is house -1');
    is($bd->count(2), -1, 'a side that is not one has no count');
    is($bd->home(-1), -1, 'and no home');
};

subtest 'the number of pieces' => sub {
    is($E->new(pieces => 7)->pieces, 7, 'seven a side');
    is($E->new(pieces => 1)->pieces, 1, 'one a side');
    for my $bad (0, 8, -1, 'seven', '', '5.0') {
        ok(!eval { $E->new(pieces => $bad); 1 }, "pieces => '$bad' croaks");
    }
    like($@, qr/whole number from 1 to 7/, 'with a sentence');
};

subtest 'put and lift judge nothing' => sub {
    my $bd = $E->new;
    $bd->put($_, LIGHT) for 1 .. 9;
    is($bd->count(SIDE_LIGHT), 9, 'nine light pieces go down in a row on a five-piece board');
    is($bd->home(SIDE_LIGHT), -4, 'and the home goes negative');
    ok(!$bd->consistent, 'which is not consistent');
    $bd->lift($_) for 6 .. 9;
    is($bd->home(SIDE_LIGHT), 0, 'four lifted, the home is 0');
    ok($bd->consistent, 'and the board is consistent again');
    $bd->put(12, 3);
    is($bd->at(12), EMPTY, 'a piece that is not one is ignored');
    $bd->put(31, DARK);
    $bd->put(0, DARK);
    is($bd->count(SIDE_DARK), 0, 'and so is a house that is not one');
    is($bd->put(12, DARK), $bd, 'put returns the board');
    is($bd->lift(12), $bd, 'and so does lift');
    is($bd->at(12), EMPTY, 'which emptied the house');
};

subtest 'the side and the ply' => sub {
    my $bd = $E->new;
    $bd->set_side(SIDE_DARK);
    is($bd->side, SIDE_DARK, 'dark to move');
    $bd->set_side(2);
    is($bd->side, SIDE_DARK, 'a side that is not one is ignored');
    $bd->set_ply(41);
    is($bd->ply, 41, 'the ply is set');
    $bd->set_ply(-1);
    is($bd->ply, 41, 'a negative ply is ignored');
    is(other(SIDE_LIGHT), SIDE_DARK, 'other');
    is(other(SIDE_DARK), SIDE_LIGHT, 'and back');
    is(piece_of(SIDE_LIGHT), LIGHT, 'piece_of light');
    is(piece_of(SIDE_DARK), DARK, 'piece_of dark');
};

subtest 'a copy is its own board' => sub {
    my $bd = $E->new(pieces => 7);
    $bd->put(4, DARK)->set_side(SIDE_DARK)->set_ply(3);
    my $copy = $bd->clone;
    is($copy->to_string, $bd->to_string, 'the copy reads the same');
    is($copy->pieces, 7, 'with the same pieces');
    is($copy->ply, 3, 'and the same ply');
    $copy->put(5, LIGHT);
    is($bd->at(5), EMPTY, 'a change to the copy does not reach the original');
    $bd->lift(4);
    is($copy->at(4), DARK, 'nor the other way');
};

subtest 'the object owns its pointer' => sub {
    my $live = $E->live;
    {
        my $bd = $E->new;
        is(reftype($bd), 'ARRAY', 'an Engine object is an array');
        is($E->live, $live + 1, 'one board is live');
        my $copy = $bd->clone;
        is($E->live, $live + 2, 'two with a copy');
    }
    is($E->live, $live, 'and none once both are gone: DEMOLISH ran exactly once each');

    ok(!eval { $E->new(_ptr => 1234); 1 }, 'a raw pointer handed to new croaks');
    like($@, qr/made by new, of_string or clone/, 'with a sentence');
    is($E->live, $live, 'and nothing was dropped that was not made');

    my $bd = $E->new;
    ok(!eval { $bd->_ptr; 1 }, 'the pointer cannot be read from outside the class');
};

subtest 'the board is let go by C, not by a Perl DEMOLISH' => sub {
    require B;
    ok(!$E->can('DEMOLISH'), 'Game::Senet::Engine has no DEMOLISH');
    my $destroy = Game::Senet::Engine::Hold->can('DESTROY');
    ok($destroy && B::svref_2object($destroy)->XSUB, 'and its hold\'s DESTROY is an XSUB');
    my $f = sub { die "the message survives\n" };
    eval { $f->($E->new) };
    is($@, "the message survives\n",
        'an exception past a temporary board keeps its message (empty on 5.14 to 5.26 with a DEMOLISH)');
};

done_testing();
