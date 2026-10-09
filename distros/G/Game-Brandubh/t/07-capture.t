use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine ':all';
use Game::Brandubh::Test::Squares qw(sq name wire unwire roller);
my $E = 'Game::Brandubh::Engine';

sub board { my ($bd, $err) = $E->of_string($_[0]); die "refused $_[0]: $err" unless $bd; $bd }

sub names { join ' ', sort map { name($_) } @_ }

# a move as the twin writes it: d1d3xc3,e3 then # for the king taken and + for
# the king home
sub annotated {
    my ($bd, $mv, $v) = @_;
    my ($flags, @squares) = $bd->preview($mv, $v);
    my $text = wire($mv);
    $text .= 'x' . join(',', sort map { name($_) } @squares) if @squares;
    $text .= '#' if $flags & KING_TAKEN;
    $text .= '+' if $flags & KING_HOME;
    return $text;
}

sub random_board {
    my ($roll) = @_;
    my $bd = $E->new(empty => 1);
    my $density = 3 + $roll->(4);
    for my $s ($E->all_squares) {
        my $what = $roll->($density);
        $bd->put($s, $what) if $what == ATTACKER || $what == DEFENDER;
        $bd->put($s, KING) if $what == KING && $roll->(4) == 0;
    }
    $bd->set_side($roll->(2) ? DEFENDERS : ATTACKERS);
    return $bd;
}

# THE ONE PREDICATE, asked square by square on a board built to hold every
# kind of answer.
subtest 'hostile_to' => sub {
    my $bd = board('6d/7/2a4/3k3/4d2/7/7 a');
    my @table = (
        # square   to attackers   to defenders   why
        [ 'c5',    0,             1,             'an attacker' ],
        [ 'e3',    1,             0,             'a defender' ],
        [ 'd4',    1,             0,             'the king on the throne: a piece, judged as one' ],
        [ 'g7',    1,             0,             'a defender standing on a corner: a piece, judged as one' ],
        [ 'a1',    1,             1,             'an empty corner, to both sides' ],
        [ 'a7',    1,             1,             'another' ],
        [ 'g1',    1,             1,             'and the third empty one' ],
        [ 'b2',    0,             0,             'an empty square that is not marked' ],
        [ 'd3',    0,             0,             'an empty square beside the throne' ],
    );
    for my $row (@table) {
        my ($square, $to_a, $to_d, $why) = @$row;
        is(!!$bd->hostile_to(sq($square), ATTACKERS), !!$to_a, "$square to the attackers: $why");
        is(!!$bd->hostile_to(sq($square), DEFENDERS), !!$to_d, "$square to the defenders");
    }

    $bd->lift(sq('d4'));
    ok($bd->hostile_to(sq('d4'), ATTACKERS), 'the throne, once empty, is hostile to the attackers');
    ok($bd->hostile_to(sq('d4'), DEFENDERS), 'and to the defenders');

    my @ring = grep { !$E->on_board($_) } 0 .. 80;
    is(scalar(grep { $bd->hostile_to($_, ATTACKERS) || $bd->hostile_to($_, DEFENDERS) } @ring), 0,
        'no cell of the ring is hostile to anybody');
    ok(!$bd->hostile_to(-1, ATTACKERS) && !$bd->hostile_to(500, DEFENDERS), 'nor is a number off both ends');
};

# The claim in the header: a capture reads the neighbour and the square beyond
# it, and when the neighbour is on the edge the square beyond is the ring,
# which is not hostile. All four edges, both sides.
subtest 'nothing is captured against the edge' => sub {
    for my $case (
        [ 'd1', 'd2', 'a2' ], [ 'd7', 'd6', 'a6' ], [ 'a3', 'b3', 'b7' ], [ 'g5', 'f5', 'f1' ],
    ) {
        my ($edge, $to, $from) = @$case;
        for my $pair ([ ATTACKER, DEFENDER, ATTACKERS ], [ DEFENDER, ATTACKER, DEFENDERS ], [ ATTACKER, KING, ATTACKERS ]) {
            my ($mover, $prey, $side) = @$pair;
            my $bd = $E->new(empty => 1);
            $bd->put(sq($edge), $prey)->put(sq($from), $mover)->set_side($side);
            my ($flags, @squares) = $bd->preview(unwire("$from$to"));
            is(names(@squares), '', "piece $prey on $edge, piece $mover arriving on $to: nothing taken");
        }
    }
};

subtest 'only the piece that moved captures' => sub {
    my $bd = board('7/a2d2d/7/7/2a1a2/7/7 d');
    my ($flags) = $bd->do_move(unwire('d6d3'));
    is($flags, 0, 'a defender moves between two attackers: nothing happens');
    is($bd->at(sq('d3')), DEFENDER, 'and it stands there');

    ($flags) = $bd->do_move(unwire('a6a5'));
    is($flags, 0, 'an attacker moves somewhere else: still nothing');
    is($bd->at(sq('d3')), DEFENDER, 'the defender is not taken by a sandwich nobody just made');

    $bd->do_move(unwire('g6g5'));
    $bd->do_move(unwire('c3c2'));
    is($bd->at(sq('d3')), DEFENDER, 'one of the two steps away, and it still stands');
    $bd->do_move(unwire('g5g6'));
    ($flags) = $bd->do_move(unwire('c2c3'));
    is($flags, DID_CAPTURE, 'the attacker steps BACK, and that is a move that closes on it');
    is($bd->at(sq('d3')), EMPTY, 'so now it is taken');
};

subtest 'captures_at judges the board as it stands and removes nothing' => sub {
    my $bd = board('7/7/7/7/adada2/7/7 a');
    is(names($bd->captures_at(sq('c3'))), 'b3 d3', 'the attacker on c3 closes on both neighbours');
    is(names($bd->captures_at(sq('a3'))), 'b3', 'the one on a3 closes on one');
    is(names($bd->captures_at(sq('b3'))), 'c3', 'the defender on b3 closes on the attacker between it and d3');
    is(names($bd->captures_at(sq('e3'))), 'd3', 'and the attacker on e3 on the defender between it and c3');
    is(names($bd->captures_at(sq('f3'))), '', 'an empty square captures nothing');
    is($bd->to_string, '7/7/7/7/adada2/7/7 a', 'and the board was not touched');
};

subtest 'do_move asks for a piece and an empty square, and nothing else' => sub {
    my $bd = $E->new;
    my $string = $bd->to_string;
    my $key = $bd->key_hex;

    my ($flags, $undo) = $bd->do_move($E->move(sq('b2'), sq('b3')));
    is($flags, 0, 'from an empty square: nothing');
    is($bd->to_string, $string, 'and the board, turn included, is as it was');
    $bd->undo_move($undo);
    is($bd->to_string, $string, 'the undo of a move that did nothing does nothing');

    ($flags) = $bd->do_move($E->move(sq('d1'), sq('d2')));
    is($flags, 0, 'onto an occupied square: nothing');
    is($bd->key_hex, $key, 'and the key never moved');

    ($flags) = $bd->do_move($E->move(0, sq('b3')));
    is($flags, 0, 'from the ring: nothing');

    ($flags, $undo) = $bd->do_move($E->move(sq('d1'), sq('g6')));
    is($bd->at(sq('g6')), ATTACKER, 'a move no piece could make is made all the same: legality is is_legal\'s question');
    is($bd->side, DEFENDERS, 'and the turn passes');
    $bd->undo_move($undo);
    is($bd->to_string, $string, 'and comes back');

    ok(!eval { $bd->undo_move('not an undo'); 1 }, 'a string that is not an undo croaks');
    like($@, qr/not an undo token/, 'and says so');
};

# A piece set down in the middle of four enemies by a caller that did not
# slide it there closes on four. The arrays are sized for it.
subtest 'four at once, by a move no piece could slide' => sub {
    my $bd = board('7/3a3/3d3/1ad1da1/3d3/3a3/a6 a');
    my $string = $bd->to_string;
    my $key = $bd->key_hex;

    my ($flags, $undo) = $bd->do_move($E->move(sq('a1'), sq('d4')));
    is($flags, DID_CAPTURE, 'an attacker dropped on the throne among four defenders');
    is($bd->count(DEFENDER), 0, 'takes all four');
    $bd->undo_move($undo);
    is($bd->to_string, $string, 'and all four come back');
    is($bd->key_hex, $key, 'with the key');
};

# THE TWIN'S LISTS. Every move of 513 positions under the default rule set and
# of 313 under three others, each carrying what it takes.
subtest 'every move takes what the twin says it takes' => sub {
    open my $fh, '<', "$FindBin::Bin/captures.txt" or die "t/captures.txt: $!";
    my (%rows, %seen, @bad);
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /\A#/ || $line !~ /\S/;
        my ($label, $position, $moves) = split /\t/, $line, -1;
        my %variant = map { split /=/ } grep { $_ ne 'default' } split /,/, $label;
        my $v = %variant ? \%variant : undef;
        my $bd = board($position);
        my $got = join ' ', sort map { annotated($bd, $_, $v) } $bd->moves($v);
        push @bad, "$label $position" unless $got eq ($moves // '');
        $rows{$label}++;
        $seen{capture}++ for $got =~ /x/g;
        $seen{two}++     for $got =~ /x\w\w,\w\w(?=[ #+]|\z)/g;
        $seen{three}++   for $got =~ /x\w\w,\w\w,\w\w/g;
        $seen{king}++    for $got =~ /#/g;
        $seen{home}++    for $got =~ /\+/g;
    }
    is($rows{default}, 513, '513 positions under the default rule set');
    is($rows{$_}, 313, "313 under $_") for qw(king_everywhere_two=1 king_strong=1 escape=edge);
    is(scalar(@bad), 0, 'and every list is the twin\'s list')
        or diag(join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)]);

    # what the lists held, so that "they agree" cannot mean "there was nothing
    # to disagree about"
    cmp_ok($seen{capture} // 0, '>', 1000, "capturing moves among them: $seen{capture}");
    cmp_ok($seen{two} // 0,     '>', 10,   "moves that take two: $seen{two}");
    cmp_ok($seen{three} // 0,   '>', 0,    "moves that take three: $seen{three}");
    cmp_ok($seen{king} // 0,    '>', 100,  "moves that take the king: $seen{king}");
    cmp_ok($seen{home} // 0,    '>', 100,  "moves that take the king home: $seen{home}");
};

subtest 'do then undo restores the board and the key, for every legal move' => sub {
    my $roll = roller(303);
    my ($boards, $moves, $bad, $captures, $mismatch) = (0, 0, 0, 0, 0);
    for my $i (1 .. 5000) {
        my $bd = random_board($roll);
        my ($string, $key) = ($bd->to_string, $bd->key_hex);
        $boards++;
        for my $mv ($bd->moves) {
            my ($pflags, @psquares) = $bd->preview($mv);
            my ($flags, $undo) = $bd->do_move($mv);
            $moves++;
            $captures++ if $flags & DID_CAPTURE;
            $mismatch++ unless $flags == $pflags;
            $mismatch++ unless $bd->key_hex eq $bd->key_full_hex;
            $mismatch++ if grep { $bd->at($_) != EMPTY } @psquares;
            $bd->undo_move($undo);
            $bad++ unless $bd->to_string eq $string && $bd->key_hex eq $key;
        }
    }
    is($boards, 5000, 'five thousand boards, counted');
    cmp_ok($moves, '>', 50_000, "$moves moves made and taken back");
    cmp_ok($captures, '>', 2000, "$captures of them captures");
    is($bad, 0, 'and every one came back to the string and the key it left');
    is($mismatch, 0, 'do_move reported what preview reported, emptied those squares, and kept the key');
};

# COLLECT, THEN REMOVE: every capture is decided before anything leaves the
# board, so the order of leaving cannot matter. Shown the blunt way. After the
# move and before any removal, take the victims off in every order; at each
# step the ones still standing must still be captured, no new one may appear,
# and every order must end on the board do_move makes.
sub permutations {
    my @items = @_;
    return [] unless @items;
    my @out;
    for my $i (0 .. $#items) {
        my @rest = @items;
        my ($pick) = splice @rest, $i, 1;
        push @out, [ $pick, @$_ ] for permutations(@rest);
    }
    return @out;
}

subtest 'the order pieces leave in does not matter' => sub {
    is(scalar(permutations(1, 2, 3)), 6, 'three things leave in six orders');

    my $roll = roller(60606);
    my ($multi, $orders, $bad, $triples) = (0, 0, 0, 0);
    my @extra = map { board($_) } (
        '7/6k/2a4/2d4/ad1da2/7/2a4 a',
        '7/6a/2d4/2a4/da1ad2/7/2k4 d',
        '7/7/2a4/7/7/ad1ka2/7 a',
        '3a3/7/7/2aka2/3a3/7/7 a',
        '1a5/7/2a4/2k4/2a4/7/7 a',
    );
    my $tries = 0;
    while ($multi < 400 && $tries < 400_000) {
        my $bd = @extra ? shift @extra : random_board($roll);
        $tries++;
        for my $mv ($bd->moves) {
            my ($flags, @victims) = $bd->preview($mv);
            next unless @victims >= 2;
            $multi++;
            $triples++ if @victims == 3;

            my $done = $bd->clone;
            $done->do_move($mv);

            my $to = $E->move_to($mv);
            for my $order (permutations(@victims)) {
                my $c = $bd->clone;
                $c->relocate($mv);
                my @left = @$order;
                while (@left) {
                    $bad++ unless names($c->captures_at($to)) eq names(@left);
                    $c->lift(shift @left);
                }
                $bad++ if $c->captures_at($to);
                $bad++ unless $c->to_string eq $done->to_string;
                $orders++;
            }
        }
    }
    cmp_ok($multi, '>=', 400, "$multi moves that take more than one piece");
    cmp_ok($triples, '>=', 2, "$triples of them take three");
    cmp_ok($orders, '>=', 800, "$orders orders of leaving tried");
    is($bad, 0, 'and every one ended on the same board, with nothing changing on the way');
};

done_testing();
