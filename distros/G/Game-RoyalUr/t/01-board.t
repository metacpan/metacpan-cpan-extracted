use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype);

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

# THE TWENTY SQUARES, WRITTEN OUT. A test that asked the engine which squares
# exist and then checked the engine agreed would pass for any answer.
my @SQUARES = qw(
    a1 b1 c1 d1       g1 h1
    a2 b2 c2 d2 e2 f2 g2 h2
    a3 b3 c3 d3       g3 h3
);
my @GAPS = qw(e1 f1 e3 f3);

sub fr {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-h])([1-3])\z/ or die "not a square: $name";
    return (ord($f) - ord('a'), $r - 1);
}

sub c { $E->cell_of(fr($_[0])) }

subtest 'twenty cells, and four squares that are not there' => sub {
    is(CELLS, 20, 'CELLS is twenty');
    is(scalar(@SQUARES), 20, 'and the list in this file has twenty names');

    my (%seen, @bad);
    for my $name (@SQUARES) {
        my ($f, $r) = fr($name);
        my $cell = $E->cell_of($f, $r);
        push @bad, "$name is not a cell" unless $cell >= 0 && $cell < 20;
        push @bad, "$name does not come apart"
            unless $E->file_of($cell) == $f && $E->row_of($cell) == $r;
        $seen{$cell}++;
    }
    is("@bad", '', 'cell_of, file_of and row_of agree for all twenty');
    is(scalar(keys %seen), 20, 'twenty distinct cells');
    is_deeply([ sort { $a <=> $b } keys %seen ], [ $E->all_cells ], 'and all_cells lists the same twenty');

    my @holes;
    for my $r (0 .. 2) {
        for my $f (0 .. 7) {
            push @holes, chr(ord('a') + $f) . ($r + 1) if $E->cell_of($f, $r) < 0;
        }
    }
    is("@holes", "@GAPS", 'cell_of answers -1 for exactly e1, f1, e3 and f3');

    is($E->cell_of(-1, 0), -1, 'file -1 is not a square');
    is($E->cell_of(8, 0),  -1, 'file 8 is not a square');
    is($E->cell_of(0, 3),  -1, 'row 3 is not a square');
    is($E->cell_of(0, -1), -1, 'nor is row -1');
    is($E->file_of(20), -1, 'cell 20 has no file');
    is($E->row_of(-1),  -1, 'cell -1 has no row');
};

subtest 'an empty board' => sub {
    my $bd = $E->new;
    my @full = grep { $bd->at($_) != EMPTY } $E->all_cells;
    is("@full", '', 'all twenty cells read EMPTY');
    is($bd->side, SIDE_LIGHT, 'light is to move');
    is($bd->hand(SIDE_LIGHT), 7, 'seven in light hand');
    is($bd->hand(SIDE_DARK),  7, 'seven in dark hand');
    is($bd->home(SIDE_LIGHT), 0, 'none of light home');
    is($bd->home(SIDE_DARK),  0, 'none of dark home');
    is($bd->count(SIDE_LIGHT) + $bd->count(SIDE_DARK), 0, 'and nothing on the board');
    is($bd->at(-1), -1, 'a negative cell is not a cell');
    is($bd->at(20), -1, 'nor is one past the end');
};

subtest 'the number of pieces' => sub {
    is($E->new(pieces => 5)->hand(SIDE_DARK), 5, 'five a side');
    is($E->new(pieces => 0)->hand(SIDE_LIGHT), 0, 'none a side');
    for my $bad (8, -1, 'seven', '') {
        ok(!eval { $E->new(pieces => $bad); 1 }, "pieces => '$bad' croaks");
    }
    like($@, qr/whole number from 0 to 7/, 'with a sentence');
};

# THE LIST IS WRITTEN OUT, for the reason the squares are.
subtest 'the rosettes are exactly these five' => sub {
    my %rosette = map { $_ => 1 } qw(a1 g1 a3 g3 d2);
    my @bad = grep { !!$E->is_rosette(c($_)) != !!$rosette{$_} } @SQUARES;
    is("@bad", '', 'every square answers as the list says');
    is(scalar(grep { $E->is_rosette($_) } $E->all_cells), 5, 'five of them');
    ok(!$E->is_rosette(-1), 'a number that is not a cell is not a rosette');
    ok(!$E->is_rosette(20), 'at either end');
};

subtest 'put and lift judge nothing' => sub {
    my $bd = $E->new;
    is($bd->put(c('d2'), DARK), $bd, 'put returns the board');
    is($bd->at(c('d2')), DARK, 'a dark piece on d2');
    is($bd->hand(SIDE_DARK), 7, 'and the hand it did not come from is still seven');

    $bd->put(c($_), LIGHT) for qw(a1 b1 c1 d1 g1 h1 a2 b2);
    is($bd->count(SIDE_LIGHT), 8, 'eight light pieces, one more than a side has');
    ok(!$bd->consistent(7), 'which is not consistent, and nothing refused it');

    $bd->put(c('d2'), LIGHT);
    is($bd->at(c('d2')), LIGHT, 'a put replaces what stood there');
    is($bd->count(SIDE_DARK), 0, 'and the piece it replaced is gone');

    is($bd->lift(c('d2')), $bd, 'lift returns the board');
    is($bd->at(c('d2')), EMPTY, 'and the cell is empty');

    my $before = $bd->to_string;
    $bd->put(c('h3'), 3)->put(c('h3'), -1)->put(-1, LIGHT)->put(20, DARK);
    is($bd->to_string, $before, 'a value that names nothing, and a cell that is none, change nothing');
};

subtest 'the hands and the homes' => sub {
    my $bd = $E->new;
    is($bd->set_hand(SIDE_LIGHT, 3), $bd, 'set_hand returns the board');
    is($bd->set_home(SIDE_DARK, 2),  $bd, 'and so does set_home');
    is($bd->hand(SIDE_LIGHT), 3, 'light has three in hand');
    is($bd->hand(SIDE_DARK),  7, 'dark still seven: the two hands are two numbers');
    is($bd->home(SIDE_DARK),  2, 'dark has two home');
    is($bd->home(SIDE_LIGHT), 0, 'light none');

    $bd->set_hand(SIDE_LIGHT, 8)->set_hand(SIDE_LIGHT, -1)->set_home(SIDE_DARK, 8)->set_hand(2, 1);
    is($bd->hand(SIDE_LIGHT), 3, 'a hand outside 0 to 7 is ignored');
    is($bd->home(SIDE_DARK),  2, 'and a home');
    is($bd->hand(2), -1, 'a side that does not exist has no hand');
    is($bd->home(-1), -1, 'and no home');
    is($bd->count(2), -1, 'and no pieces');
};

subtest 'consistent adds up hand, board and home for each side' => sub {
    my $bd = $E->new;
    ok($bd->consistent(7), 'the start is consistent at seven');
    ok(!$bd->consistent(5), 'and not at five');
    $bd->put(c('d1'), LIGHT);
    ok(!$bd->consistent(7), 'a piece put down with the hand left full is one too many');
    $bd->set_hand(SIDE_LIGHT, 6);
    ok($bd->consistent(7), 'six in hand and one on the board is seven');
    $bd->set_home(SIDE_DARK, 1);
    ok(!$bd->consistent(7), 'dark with one home and seven in hand is eight');
    $bd->set_hand(SIDE_DARK, 6);
    ok($bd->consistent(7), 'and with six in hand is seven again');
};

subtest 'the side to move' => sub {
    my $bd = $E->new;
    is($bd->set_side(SIDE_DARK), $bd, 'set_side returns the board');
    is($bd->side, SIDE_DARK, 'dark to move');
    $bd->set_side(7);
    is($bd->side, SIDE_DARK, 'a side that does not exist changes nothing');
    $bd->set_side(SIDE_LIGHT);
    is($bd->side, SIDE_LIGHT, 'and back');
    is(other(SIDE_LIGHT), SIDE_DARK, 'the other side of light');
    is(other(SIDE_DARK), SIDE_LIGHT, 'and of dark');
    is(piece_of(SIDE_LIGHT), LIGHT, 'the piece of the light side');
    is(piece_of(SIDE_DARK),  DARK,  'and of the dark side');
};

subtest 'a clone shares nothing' => sub {
    my $bd = $E->new;
    $bd->put(c('a2'), LIGHT)->set_hand(SIDE_LIGHT, 6);
    my $copy = $bd->clone;
    is($copy->to_string, $bd->to_string, 'the clone starts as the same position');
    $copy->put(c('b2'), DARK)->set_side(SIDE_DARK)->set_hand(SIDE_DARK, 6)->set_home(SIDE_LIGHT, 1);
    is($bd->at(c('b2')), EMPTY, 'a put on the clone does not reach the original');
    is($bd->side, SIDE_LIGHT, 'nor does its side');
    is($bd->hand(SIDE_DARK), 7, 'nor its hand');
    is($bd->home(SIDE_LIGHT), 0, 'nor its home');
    isnt($copy->key_hex, $bd->key_hex, 'and the two keys have parted');
};

# The object is a Sugar object: an array, with the board pointer behind a
# private attribute. That is the whole reason for the class being written this
# way, so it is asserted and not assumed.
subtest 'the pointer cannot be reached from outside' => sub {
    my $bd = $E->new;
    is(reftype($bd), 'ARRAY', 'the object is an array, so there is no ->{slot} to read');
    ok(!eval { my $p = $bd->_ptr; 1 }, 'reading the pointer from outside dies');
    like($@, qr/private/, 'and says why');
    ok(!eval { $bd->_ptr(0); 1 }, 'so does writing it');
    is($bd->hand(SIDE_LIGHT), 7, 'and the board is still there afterwards');

    my $before = $E->live;
    ok(!eval { $E->new(_ptr => 12345); 1 }, 'a pointer handed to new is refused');
    like($@, qr/made by new, of_string or clone/, 'with a sentence');
    is($E->live, $before, 'and the refusal dropped nothing that was not its own');
};

# Counted by the engine: boards handed out and not yet dropped. A destructor
# that never ran leaves the count high, and one that ran twice takes it below
# where it started.
subtest 'a board is dropped once, when the last reference goes' => sub {
    my $start = $E->live;
    {
        my $bd = $E->new;
        is($E->live, $start + 1, 'one board made');
        my $again = $bd;
        undef $bd;
        is($E->live, $start + 1, 'a second reference keeps it');
        my $copy = $again->clone;
        is($E->live, $start + 2, 'a clone is a second board');
        my ($o) = $E->of_string('4xx2/3d4/4xx2 l 7 0 6 0');
        is($E->live, $start + 3, 'and a board from a string is a third');
    }
    is($E->live, $start, 'all three are gone at the end of the block, and none twice');

    my ($none, $err) = $E->of_string('junk');
    is($E->live, $start, 'a refused string leaves no board behind');
    ok(!eval { $E->new(position => 'junk'); 1 }, 'and new croaks on one');
    is($E->live, $start, 'leaving none behind either');
};

done_testing();
