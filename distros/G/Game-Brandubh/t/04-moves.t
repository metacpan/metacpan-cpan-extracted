use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine ':all';
use Game::Brandubh::Test::Squares qw(sq name wire unwire roller);
my $E = 'Game::Brandubh::Engine';

sub wires { join ' ', sort map { wire($_) } @_ }

sub board { my ($bd, $err) = $E->of_string($_[0]); die "refused $_[0]: $err" unless $bd; $bd }

# a random board that could hold anything, from the test's own generator
sub random_board {
    my ($roll) = @_;
    my $bd = $E->new(empty => 1);
    my $density = 3 + $roll->(6);
    for my $s ($E->all_squares) {
        my $what = $roll->($density);
        $bd->put($s, $what) if $what >= 1 && $what <= 3;
    }
    $bd->set_side($roll->(2) ? DEFENDERS : ATTACKERS);
    return $bd;
}

subtest 'a move packs two squares and gives them back' => sub {
    my ($pairs, $bad) = (0, 0);
    my %seen;
    for my $from ($E->all_squares) {
        for my $to ($E->all_squares) {
            my $mv = $E->move($from, $to);
            $pairs++;
            $bad++ unless $E->move_from($mv) == $from && $E->move_to($mv) == $to;
            $seen{$mv}++;
        }
    }
    is($pairs, 49 * 49, 'every pair of squares, counted');
    is($bad, 0, 'comes apart into the two squares it was made of');
    is(scalar(keys %seen), 49 * 49, 'and no two pairs pack to one number');
    is(wire($E->move(sq('d1'), sq('d3'))), 'd1d3', 'the test helper reads a move as the engine packs it');
};

# COUNTED BY HAND in plan_game_brandubh/02 before any program produced a
# number. These two are the only rows of the oracle with no author but a person.
subtest 'the set-up, by hand' => sub {
    my $bd = $E->new;
    is(scalar($bd->moves), 40, 'forty moves for the attackers');
    is(wires($bd->moves),
        'a4a2 a4a3 a4a5 a4a6 b4b1 b4b2 b4b3 b4b5 b4b6 b4b7 '
      . 'd1b1 d1c1 d1e1 d1f1 d2a2 d2b2 d2c2 d2e2 d2f2 d2g2 '
      . 'd6a6 d6b6 d6c6 d6e6 d6f6 d6g6 d7b7 d7c7 d7e7 d7f7 '
      . 'f4f1 f4f2 f4f3 f4f5 f4f6 f4f7 g4g2 g4g3 g4g5 g4g6',
        'and they are these forty');

    $bd->set_side(DEFENDERS);
    is(scalar($bd->moves), 24, 'twenty-four for the defenders');
    is(wires($bd->moves),
        'c4c1 c4c2 c4c3 c4c5 c4c6 c4c7 d3a3 d3b3 d3c3 d3e3 d3f3 d3g3 '
      . 'd5a5 d5b5 d5c5 d5e5 d5f5 d5g5 e4e1 e4e2 e4e3 e4e5 e4e6 e4e7',
        'six for each defender and none for the king');
};

subtest 'a list in list context, a count in scalar context' => sub {
    my $bd = $E->new;
    my @list = $bd->moves;
    my $count = $bd->moves;
    is($count, scalar @list, 'the count is the length of the list');
    is($bd->to_string, '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', 'and asking moved nothing');
};

subtest 'the order of the list is square order, then left right down up' => sub {
    my $bd = board('7/7/7/7/2a4/7/7 a');
    is(join(' ', map { wire($_) } $bd->moves),
        'c3b3 c3a3 c3d3 c3e3 c3f3 c3g3 c3c2 c3c1 c3c4 c3c5 c3c6 c3c7',
        'one piece: left, right, down, up, nearest square first');
    my $two = board('7/7/7/7/2a4/7/a6 a');
    is((map { wire($_) } $two->moves)[0], 'a1b1', 'a1 is asked before c3');
};

# THE TWIN'S LISTS. t/moves.txt was written by a second program, in another
# language, from the rules text alone. Two hundred positions under three rule
# sets, each with its whole sorted move list.
subtest 'two hundred positions agree with the twin, move for move' => sub {
    open my $fh, '<', "$FindBin::Bin/moves.txt" or die "t/moves.txt: $!";
    my (%rows, @bad);
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /\A#/ || $line !~ /\S/;
        my ($label, $position, $moves) = split /\t/, $line, -1;
        my %variant = map { split /=/ } grep { $_ ne 'default' } split /,/, $label;
        my $bd = board($position);
        my $got = wires($bd->moves(%variant ? \%variant : undef));
        push @bad, "$label $position" unless $got eq ($moves // '');
        $rows{$label}++;
    }
    is($rows{default}, 200, 'two hundred under the default rule set');
    is($rows{'throne_pass=0'}, 200, 'two hundred with the throne closed to passing');
    is($rows{'throne_reentry=1'}, 200, 'two hundred with the king allowed back');
    is(scalar(@bad), 0, 'and every list is the twin\'s list')
        or diag(join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)]);
};

subtest 'is_legal is the list' => sub {
    my $roll = roller(4041);
    my ($pairs, $bad) = (0, 0);
    for my $i (1 .. 40) {
        my $bd = random_board($roll);
        my %legal = map { $_ => 1 } $bd->moves;
        for my $from ($E->all_squares) {
            for my $to ($E->all_squares) {
                my $mv = $E->move($from, $to);
                $pairs++;
                $bad++ if !!$bd->is_legal($mv) != !!$legal{$mv};
            }
        }
    }
    is($pairs, 40 * 2401, 'every pair of squares on forty boards');
    is($bad, 0, 'is legal exactly when it is in the list');
};

# why_not is a SECOND implementation of the two rules, by necessity: it has to
# say what was wrong. So it is held against the first on every pair of squares.
subtest 'why_not is WHY_OK exactly when the move is legal' => sub {
    my $roll = roller(20261008);
    my ($pairs, $bad, $legal_seen, %why) = (0, 0, 0);
    for my $v (undef, { throne_pass => 0 }, { throne_reentry => 1 },
               { throne_pass => 0, throne_reentry => 1 }) {
        for my $i (1 .. 125) {
            my $bd = random_board($roll);
            my %legal = map { $_ => 1 } $bd->moves($v);
            $legal_seen += keys %legal;
            for my $from ($E->all_squares) {
                for my $to ($E->all_squares) {
                    my $why = $bd->why_not($from, $to, $v);
                    $pairs++;
                    $why{$why}++;
                    $bad++ if ($why == WHY_OK) != !!$legal{ $E->move($from, $to) };
                }
            }
        }
    }
    is($pairs, 500 * 2401, 'every pair of squares on five hundred boards, under four rule sets');
    is($bad, 0, 'and the two agree on all of them');
    cmp_ok($legal_seen, '>', 5000, "with legal moves among them ($legal_seen)");
    is(join(' ', sort { $a <=> $b } keys %why), '0 2 3 4 5 6 7 8',
        'and every reason a board can give was given');
};

subtest 'each reason, from a move written to earn it' => sub {
    my $bd = board('k5a/7/7/3d3/7/7/a5a a');
    my @cases = (
        [ 'a1', 'a3', WHY_OK,         'an attacker up the file' ],
        [ 'b2', 'b3', WHY_NO_PIECE,   'an empty square' ],
        [ 'd4', 'd5', WHY_NOT_YOURS,  'a defender, on the attackers\' turn' ],
        [ 'a7', 'b7', WHY_NOT_YOURS,  'the king, on the attackers\' turn' ],
        [ 'a1', 'a1', WHY_NO_MOVE,    'a piece to its own square' ],
        [ 'a1', 'b2', WHY_NOT_A_LINE, 'a diagonal' ],
        [ 'a1', 'c2', WHY_NOT_A_LINE, 'a knight\'s move' ],
        [ 'a1', 'a7', WHY_BLOCKED,    'onto another piece' ],
        [ 'a1', 'g1', WHY_BLOCKED,    'onto one of its own' ],
        [ 'g7', 'd7', WHY_OK,         'an attacker along the top rank' ],
    );
    for my $case (@cases) {
        my ($from, $to, $want, $what) = @$case;
        is($bd->why_not(sq($from), sq($to)), $want, "$from to $to: $what");
    }
    is($bd->why_not(0, sq('a1')), WHY_OFF_BOARD, 'from the ring');
    is($bd->why_not(sq('a1'), 80), WHY_OFF_BOARD, 'to the ring');
    is($bd->why_not(-5, 999), WHY_OFF_BOARD, 'between two numbers that are not squares');

    my $c = board('7/7/7/a2d3/7/7/a5k d');
    is($c->why_not(sq('d4'), sq('a4')), WHY_BLOCKED, 'a defender onto an attacker');
    is($c->why_not(sq('d4'), sq('d7')), WHY_OK, 'a defender off the throne');
    is($c->why_not(sq('g1'), sq('g7')), WHY_OK, 'the king to a corner');
    is($c->why_not(sq('g1'), sq('b1')), WHY_OK, 'the king along the rank');
    is($c->why_not(sq('g1'), sq('a1')), WHY_BLOCKED, 'but not onto the attacker at the end of it');
    $c->set_side(ATTACKERS);
    is($c->why_not(sq('a4'), sq('a7')), WHY_CORNER, 'an attacker onto a corner');
    is($c->why_not(sq('a4'), sq('b4')), WHY_OK, 'an attacker one step');
    is($c->why_not(sq('a4'), sq('g4')), WHY_BLOCKED, 'an attacker through the piece on the throne');

    my $t = board('7/7/7/a6/7/7/7 a');
    is($t->why_not(sq('a4'), sq('d4')), WHY_THRONE, 'an attacker stopping on the empty throne');
    is($t->why_not(sq('a4'), sq('e4')), WHY_OK, 'and one sliding across it');
    is($t->why_not(sq('a4'), sq('e4'), { throne_pass => 0 }), WHY_THRONE,
        'which is the throne\'s refusal when the rule set closes it');
};

subtest 'relocate judges nothing' => sub {
    my $bd = $E->new;
    my $key = $bd->key_hex;
    is($bd->relocate($E->move(sq('d1'), sq('d4'))), $bd, 'relocate returns the board');
    is($bd->at(sq('d4')), ATTACKER, 'an attacker now stands on the throne, where the king was');
    is($bd->count(KING), 0, 'and the king it replaced is gone');
    is($bd->side, DEFENDERS, 'the turn has passed');
    is($bd->key_hex, $bd->key_full_hex, 'the key was kept through it');
    isnt($bd->key_hex, $key, 'and is not the key it started with');
    $bd->relocate($E->move(0, 80));
    is($bd->side, DEFENDERS, 'a move between two cells of the ring does nothing at all');
};

# moves_max is a PROOF, written in the header: along one line an empty square
# is reached by at most two pieces. This measures against it and reports what
# it found, so the constant and the board can be seen side by side.
subtest 'no board has more moves than the bound' => sub {
    is($E->moves_max, 144, 'the buffer is 144');
    my $roll = roller(140);
    my ($most, $where, $boards) = (0, '', 0);
    for my $i (1 .. 20_000) {
        my $bd = $E->new(empty => 1);
        my $density = 3 + $roll->(12);
        my $side = $roll->(2) ? ATTACKER : DEFENDER;
        for my $s ($E->all_squares) {
            $bd->put($s, $side) if $roll->($density) == 0;
        }
        $bd->set_side($side == ATTACKER ? ATTACKERS : DEFENDERS);
        my $n = $bd->moves;
        ($most, $where) = ($n, $bd->to_string) if $n > $most;
        $boards++;
    }
    is($boards, 20_000, 'twenty thousand boards of one side only, counted');
    cmp_ok($most, '<=', 140, "the most moves seen is $most, at $where");
    cmp_ok($most, '>', 60, 'and the search was looking at crowded boards, not empty ones');

    my $kings = board('k1k1k1k/7/k1k1k1k/7/k1k1k1k/7/k1k1k1k d');
    cmp_ok(scalar($kings->moves), '<=', 140, 'sixteen kings on a lattice: ' . scalar($kings->moves));
};

subtest 'a variant is a hash reference, and a misspelt field is refused' => sub {
    my $bd = $E->new;
    is(scalar($bd->moves(undef)), 40, 'undef is the default');
    is(scalar($bd->moves({})), 40, 'so is an empty hash');
    ok(!eval { $bd->moves({ throne_pas => 0 }); 1 }, 'a field that does not exist croaks');
    like($@, qr/no variant field is called 'throne_pas'/, 'and names it');
    ok(!eval { $bd->moves('default'); 1 }, 'a string is not a variant');
    ok(!eval { $bd->moves({ escape => 'sideways' }); 1 }, 'nor is an escape that is neither');
    is(scalar($bd->moves({ escape => 'edge', repeat => 2, ply_cap => 100,
                          king_strong => 0, king_everywhere_two => 1 })), 40,
        'the fields that wait for a later version are accepted and change nothing here');
};

done_testing();
