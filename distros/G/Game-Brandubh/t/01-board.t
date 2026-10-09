use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype);

use Game::Brandubh::Engine ':all';
my $E = 'Game::Brandubh::Engine';

# A square by its name. WRITTEN HERE AND NOT BORROWED FROM THE ENGINE: the
# arithmetic is the header's, typed out a second time, so a stride that moved
# would disagree with this and not with itself.
sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-g])([1-7])\z/ or die "not a square: $name";
    return ($r - 1 + 1) * 9 + (ord($f) - ord('a') + 1);
}

subtest 'the set-up is the cross' => sub {
    my $bd = $E->new;
    is($bd->count(ATTACKER), 8, 'eight attackers');
    is($bd->count(DEFENDER), 4, 'four defenders');
    is($bd->count(KING),     1, 'one king');
    is($bd->king_square, sq('d4'), 'the king is on d4');
    is($bd->side, ATTACKERS, 'the attackers move first');

    # every one of the forty-nine, named, so a piece on the wrong arm cannot
    # hide behind a count that still adds up
    my %want = (
        (map { $_ => ATTACKER } qw(d1 d2 d6 d7 a4 b4 f4 g4)),
        (map { $_ => DEFENDER } qw(d3 d5 c4 e4)),
        d4 => KING,
    );
    my @wrong;
    for my $r (1 .. 7) {
        for my $f ('a' .. 'g') {
            my $name = "$f$r";
            my $got = $bd->at(sq($name));
            push @wrong, "$name is $got" unless $got == ($want{$name} // EMPTY);
        }
    }
    is("@wrong", '', 'all forty-nine squares hold what the diagram shows');
};

subtest 'a square is a padded index' => sub {
    my (%seen, @bad);
    for my $r (0 .. 6) {
        for my $f (0 .. 6) {
            my $s = $E->square_of($f, $r);
            push @bad, "($f,$r) gave $s" unless $s == ($r + 1) * 9 + ($f + 1);
            push @bad, "($f,$r) does not come apart"
                unless $E->file_of($s) == $f && $E->rank_of($s) == $r;
            $seen{$s}++;
        }
    }
    is("@bad", '', 'square_of, file_of and rank_of agree for all forty-nine');
    is(scalar(keys %seen), 49, 'forty-nine distinct squares');
    is(scalar($E->all_squares), 49, 'all_squares lists forty-nine');
    is_deeply([ sort { $a <=> $b } $E->all_squares ], [ sort { $a <=> $b } keys %seen ],
        'and they are the same forty-nine');

    is($E->square_of(-1, 0), -1, 'file -1 is not a square');
    is($E->square_of(7, 0),  -1, 'file 7 is not a square');
    is($E->square_of(0, 7),  -1, 'rank 7 is not a square');
    is($E->file_of(0), -1, 'cell 0 has no file');
    is($E->rank_of(80), -1, 'cell 80 has no rank');
};

subtest 'the ring is border, all thirty-two cells of it' => sub {
    my $bd = $E->new(empty => 1);
    my ($ring, $inside, @bad) = (0, 0);
    for my $cell (0 .. 80) {
        if ($E->on_board($cell)) {
            $inside++;
            push @bad, "cell $cell is on the board and reads " . $bd->at($cell)
                unless $bd->at($cell) == EMPTY;
        }
        else {
            $ring++;
            push @bad, "cell $cell is off the board and reads " . $bd->at($cell)
                unless $bd->at($cell) == BORDER;
        }
    }
    is($inside, 49, 'forty-nine cells are squares');
    is($ring,   32, 'thirty-two are the ring');
    is("@bad", '', 'and each reads as what it is');
    is($bd->at(-1),  BORDER, 'a negative cell is border');
    is($bd->at(81),  BORDER, 'a cell past the end is border');
    is($bd->at(999), BORDER, 'and so is one a long way past it');
};

subtest 'the ring cannot be written, and neither can nonsense' => sub {
    my $bd = $E->new(empty => 1);
    my $key = $bd->key_hex;
    $bd->put(0, ATTACKER);
    $bd->put(8, KING);
    $bd->put(80, DEFENDER);
    is($bd->at(0), BORDER, 'a put on the ring leaves the ring');
    is($bd->count(ATTACKER) + $bd->count(DEFENDER) + $bd->count(KING), 0, 'and no piece arrived');
    $bd->put(sq('c3'), BORDER);
    is($bd->at(sq('c3')), EMPTY, 'a border is not a piece and is not put');
    $bd->put(sq('c3'), 9);
    is($bd->at(sq('c3')), EMPTY, 'neither is a number that names nothing');
    is($bd->key_hex, $key, 'and the key never moved');
};

# THE THREE LISTS ARE WRITTEN OUT. A test that asked the engine which squares
# are corners and then checked the engine agreed would pass for any answer.
subtest 'the special squares are exactly these' => sub {
    my %throne = (d4 => 1);
    my %corner = map { $_ => 1 } qw(a1 g1 a7 g7);
    my %beside = map { $_ => 1 } qw(d3 d5 c4 e4);
    my (@bad, %n);
    for my $r (1 .. 7) {
        for my $f ('a' .. 'g') {
            my $name = "$f$r";
            my $s = sq($name);
            push @bad, "$name throne"  if !!$E->is_throne($s)     != !!$throne{$name};
            push @bad, "$name corner"  if !!$E->is_corner($s)     != !!$corner{$name};
            push @bad, "$name beside"  if !!$E->beside_throne($s) != !!$beside{$name};
            $n{throne}++ if $E->is_throne($s);
            $n{corner}++ if $E->is_corner($s);
            $n{beside}++ if $E->beside_throne($s);
        }
    }
    is("@bad", '', 'every square answers all three questions as the lists say');
    is($n{throne}, 1, 'one throne');
    is($n{corner}, 4, 'four corners');
    is($n{beside}, 4, 'four squares beside the throne');

    my @ring_hits = grep { !$E->on_board($_)
        && ($E->is_throne($_) || $E->is_corner($_) || $E->beside_throne($_)) } 0 .. 80;
    is("@ring_hits", '', 'no cell of the ring is special');
};

subtest 'a special square is geometry, not contents' => sub {
    my $bd = $E->new;
    ok($E->is_throne(sq('d4')), 'd4 is the throne with the king on it');
    $bd->lift(sq('d4'));
    is($bd->at(sq('d4')), EMPTY, 'the empty throne reads EMPTY like any empty square');
    ok($E->is_throne(sq('d4')), 'and is still the throne');
    is($bd->king_square, -1, 'with no king on the board, king_square is -1');
};

subtest 'the king is on the defenders side' => sub {
    is($E->side_of(ATTACKER), ATTACKERS, 'an attacker attacks');
    is($E->side_of(DEFENDER), DEFENDERS, 'a defender defends');
    is($E->side_of(KING),     DEFENDERS, 'the king is a defender-side piece');
    is($E->side_of(EMPTY),  -1, 'an empty square is on no side');
    is($E->side_of(BORDER), -1, 'nor is the border');
    is(other(ATTACKERS), DEFENDERS, 'the other side of the attackers');
    is(other(DEFENDERS), ATTACKERS, 'and of the defenders');
};

subtest 'put and lift judge nothing' => sub {
    my $bd = $E->new(empty => 1);
    $bd->put(sq('a1'), KING)->put(sq('g7'), KING)->put(sq('d4'), DEFENDER);
    is($bd->count(KING), 2, 'two kings, both on corners');
    is($bd->at(sq('d4')), DEFENDER, 'a defender on the throne');
    $bd->put(sq('a1'), ATTACKER);
    is($bd->at(sq('a1')), ATTACKER, 'a put replaces what stood there');
    is($bd->count(KING), 1, 'and the piece it replaced is gone');
    is($bd->lift(sq('a1')), $bd, 'lift returns the board');
    is($bd->at(sq('a1')), EMPTY, 'and the square is empty');
};

subtest 'the side to move' => sub {
    my $bd = $E->new;
    is($bd->set_side(DEFENDERS), $bd, 'set_side returns the board');
    is($bd->side, DEFENDERS, 'the defenders to move');
    $bd->set_side(7);
    is($bd->side, DEFENDERS, 'a side that does not exist changes nothing');
    $bd->set_side(ATTACKERS);
    is($bd->side, ATTACKERS, 'and back');
};

subtest 'a clone shares nothing' => sub {
    my $bd = $E->new;
    my $c = $bd->clone;
    is($c->to_string, $bd->to_string, 'the clone starts as the same position');
    $c->put(sq('a2'), DEFENDER)->set_side(DEFENDERS);
    is($bd->at(sq('a2')), EMPTY, 'a put on the clone does not reach the original');
    is($bd->side, ATTACKERS, 'nor does its side');
    isnt($c->key_hex, $bd->key_hex, 'and the two keys have parted');
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
    is($bd->count(KING), 1, 'and the board is still there afterwards');

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
        my $c = $again->clone;
        is($E->live, $start + 2, 'a clone is a second board');
        my ($o) = $E->of_string('7/7/7/3k3/7/7/7 d');
        is($E->live, $start + 3, 'and a board from a string is a third');
    }
    is($E->live, $start, 'all three are gone at the end of the block, and none twice');

    my ($none, $err) = $E->of_string('junk');
    is($E->live, $start, 'a refused string leaves no board behind');
    ok(!eval { $E->new(position => 'junk'); 1 }, 'and new croaks on one');
    is($E->live, $start, 'leaving none behind either');
};

done_testing();
