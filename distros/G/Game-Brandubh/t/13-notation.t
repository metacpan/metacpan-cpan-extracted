use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Notation ':all';
use Game::Brandubh::Engine qw(KING KING_HOME KING_TAKEN DID_CAPTURE ATTACKERS DEFENDERS);
use Game::Brandubh::Rules qw(:all);
use Game::Brandubh::Test::Squares qw(sq name wire unwire roller);
my $E = 'Game::Brandubh::Engine';
my $R = 'Game::Brandubh::Rules';

# every warning is a failure: half of this file hands the module rubbish, and
# rubbish is meant to come back as "no", quietly
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my @FILES = ('a' .. 'g');
my @ALL = map { my $r = $_; map { "$_$r" } @FILES } 1 .. 7;

subtest 'a square, both ways' => sub {
    is(scalar(@ALL), 49, 'forty-nine names');
    my @bad;
    for my $r (0 .. 6) {
        for my $f (0 .. 6) {
            my $want = $FILES[$f] . ($r + 1);
            my $got = square_name($f, $r);
            push @bad, "($f,$r) named " . ($got // 'undef') unless defined $got && $got eq $want;
            my @back = square_parse($want);
            push @bad, "$want parsed (@back)" unless @back == 2 && $back[0] == $f && $back[1] == $r;
        }
    }
    is("@bad", '', 'all forty-nine, name and parse, agree with the letters and digits written here');

    is(square_name(0, 0), 'a1', 'file 0 is a and rank 0 is 1');
    is(square_name(6, 6), 'g7', 'file 6 is g and rank 6 is 7');
    is(square_name(3, 3), 'd4', 'the throne');
    is_deeply([ square_parse('D4') ], [ 3, 3 ], 'an upper-case name is read');
    is(square_name(3, 3), lc square_name(3, 3), 'and a name is always written in lower case');

    # the engine's own squares, named by the test helper, are the same names
    is(join(' ', map { name($_) } $E->all_squares), "@ALL", 'the engine counts its squares in the same order');
};

subtest 'what is not a square is not one, quietly' => sub {
    for my $bad ('h1', 'a8', 'a0', 'aa', '11', '', ' a1', 'a1 ', 'a11', 'a', '1a', "a1\n", undef, [], {}, \'a1', 7) {
        my $shown = defined $bad ? (ref $bad ? ref($bad) . ' ref' : "'$bad'") : 'undef';
        $shown =~ s/\n/\\n/;
        is_deeply([ square_parse($bad) ], [], "$shown parses to the empty list");
    }
    is(scalar(() = square_parse('h1')), 0, 'the empty list, not a list of one undef');

    for my $pair ([ 7, 0 ], [ 0, 7 ], [ -1, 0 ], [ 0, -1 ], [ 'a', 1 ], [ undef, 1 ], [ 1, undef ], [ 1.5, 2 ], [ [], 1 ]) {
        is(square_name(@$pair), undef, 'square_name(' . join(', ', map { $_ // 'undef' } @$pair) . ') is undef');
    }
};

subtest 'a stored move, both ways, for every pair of squares' => sub {
    my ($pairs, $bad) = (0, 0);
    my %seen;
    for my $from (@ALL) {
        for my $to (@ALL) {
            my $move = move_wire($from, $to);
            $pairs++;
            $bad++ unless defined $move && $move eq "$from$to";
            my @back = move_split($move);
            $bad++ unless @back == 2 && $back[0] eq $from && $back[1] eq $to;
            $bad++ unless move_parse($move) eq $move;
            $seen{$move}++;
        }
    }
    is($pairs, 2401, 'every pair of squares, a square with itself included');
    is($bad, 0, 'written, split and parsed back to the same four characters');
    is(scalar(keys %seen), 2401, 'and no two pairs are written alike');

    is(move_wire('D1', 'd3'), 'd1d3', 'move_wire reads either case and writes lower');
    is(move_wire('d1', 'h3'), undef, 'and refuses a square that is not one');
    is(move_wire('d1'), undef, 'or one that is missing');

    # the engine's packed move, read by the test helper, is the same string
    is(wire($E->move(sq('d1'), sq('d3'))), move_wire('d1', 'd3'), 'the engine\'s d1 to d3 is this module\'s d1d3');
};

subtest 'from then to, in that order' => sub {
    is(move_wire('a1', 'g7'), 'a1g7', 'from first');
    is_deeply([ move_split('a1g7') ], [ 'a1', 'g7' ], 'and split the same way round');
    is(move_parse('a1-g7'), 'a1g7', 'and parsed the same way round');
    isnt(move_wire('a1', 'g7'), move_wire('g7', 'a1'), 'the reverse move is another move');
};

# THE EDGE OF THE BOARD, IN EVERY FUNCTION THAT READS A SQUARE. A square has its
# own pattern in square_parse and the moves have another, so a rank 8 that one
# refuses the other can still let through. The first version of this file tried
# a8 and h1 as bare squares only, and a mutant that took rank 8 inside a move
# went unnoticed until the mutation run.
subtest 'rank 8, rank 0 and file h are off the board wherever they are written' => sub {
    for my $off ('a8', 'd8', 'g8', 'a0', 'd0', 'h1', 'h7', 'h8') {
        is_deeply([ square_parse($off) ], [], "$off is not a square");
        is(move_wire('d4', $off), undef, "move_wire to $off");
        is(move_wire($off, 'd4'), undef, "move_wire from $off");
        is_deeply([ move_split("d4$off") ], [], "move_split of d4$off");
        is_deeply([ move_split("${off}d4") ], [], "move_split of ${off}d4");
        is(move_parse("d4-$off"), undef, "move_parse of d4-$off");
        is(move_parse("$off-d4"), undef, "move_parse of $off-d4");
        is(move_parse("Kd4$off"), undef, "move_parse of Kd4$off");
        is(move_parse("d4-d1x$off"), undef, "move_parse of a capture on $off");
        is(move_display("d4$off"), undef, "move_display of d4$off");
        is(move_display('d4d1', { captures => [$off] }), 'd4-d1', "move_display drops a capture on $off");
        is(game_string({ moves => ["d4$off"] }), undef, "game_string with the move d4$off");
        is(game_parse("variant brandubh\nmoves d4$off\n"), undef, "game_parse with the move d4$off");
    }
    is(move_parse('a1-g7'), 'a1g7', 'while the two far corners are on it');
    is(move_parse('g7-a1'), 'g7a1', 'both ways');
};

subtest 'move_split is strict' => sub {
    is_deeply([ move_split($_) ], [], "'$_' is not a stored move")
        for 'd1-d3', 'D1D3', 'd1d3 ', ' d1d3', 'd1d', 'd1d33', 'Kd1d3', 'd1d3x', '', 'd1h3';
    is_deeply([ move_split(undef) ], [], 'nor is undef');
    is_deeply([ move_split([ 'd1d3' ]) ], [], 'nor a reference');
};

subtest 'move_parse reads what a person writes' => sub {
    my @same = (
        'd4d1', 'd4-d1', 'Kd4-d1', 'Kd4d1', 'kd4-d1', 'KD4-D1', '  d4-d1  ',
        'd4-d1xc1', 'd4-d1xc1,e1', 'd4-d1xc1,e1,d2', 'Kd4-d1xc1', 'd4d1xc1',
        'd4-d1#', 'd4-d1++', 'Kd4-d1++', 'd4-d1xc1#', 'Kd4-d1xc1,e1++',
    );
    is(move_parse($_), 'd4d1', "'$_' is d4d1") for @same;

    my @not = (
        'd4', 'd4-', '-d1', 'd4--d1', 'd4 d1', 'd4-d1x', 'd4-d1xh1', 'd4-d1x,c1', 'd4-d1xc1,',
        'd4-d1+', 'd4-d1+++', 'd4-d1##', 'd4-d1#++', 'd4-d1++#', 'Qd4-d1', 'KKd4-d1', 'd4-h1',
        'd4-d1 xc1', 'd4-d1xc1 e1', 'x', '', 'resign', "d4-d1\nd4-d1",
    );
    for my $bad (@not) {
        (my $shown = $bad) =~ s/\n/\\n/;
        is(move_parse($bad), undef, "'$shown' is not a move");
    }
    is(move_parse(undef), undef, 'nor is undef');
    is(move_parse({}), undef, 'nor a reference');
};

# WHAT A SHOWN MOVE CLAIMS IT CAPTURED IS COMMENTARY. The position decides, and
# a string that says otherwise changes nothing.
subtest 'a claimed capture is read past, not believed' => sub {
    is(move_parse('d1-d3xa1,a7,g1'), 'd1d3', 'three claimed captures, and the move is d1d3');
    is(move_parse('d1-d3xd1'), 'd1d3', 'even the claim to have captured its own square');
    is(length(move_parse('d1-d3xc3,e3#')), 4, 'what comes back is four characters and no more');
    unlike(move_parse('Kd1-d3xc3++'), qr/[xK#+,-]/, 'with none of the decoration in it');
};

subtest 'move_display writes what it is told happened' => sub {
    is(move_display('d1d3'), 'd1-d3', 'a move');
    is(move_display('d1d3', {}), 'd1-d3', 'with nothing to say');
    is(move_display('d1d3', { captures => ['c3'] }), 'd1-d3xc3', 'a capture');
    is(move_display('d1d3', { captures => [ 'e3', 'c3' ] }), 'd1-d3xc3,e3', 'two, written in order whatever order they came in');
    is(move_display('d1d3', { captures => [ 'e3', 'c3', 'd4' ] }), 'd1-d3xc3,d4,e3', 'three');
    is(move_display('e4e1', { king => 1 }), 'Ke4-e1', 'the king');
    is(move_display('e4e1', { king => 0 }), 'e4-e1', 'not the king');
    is(move_display('g2g1', { king => 1, king_home => 1 }), 'Kg2-g1++', 'the king home');
    is(move_display('c5c4', { captures => ['d4'], king_taken => 1 }), 'c5-c4xd4#', 'the king taken');
    is(move_display('a2a1', { king => 1, king_home => 1, captures => ['b1'] }), 'Ka2-a1xb1++', 'the king home with a capture');
    is(move_display('d1d3', { captures => [ 'C3', undef, 'z9', [] ] }), 'd1-d3xc3', 'rubbish among the captures is dropped');
    is(move_display('d1d3', { captures => 'c3' }), 'd1-d3', 'and captures that are not a list are no captures');
    is(move_display('d1-d3'), undef, 'a move that is not a stored move is undef');
    is(move_display(undef), undef, 'and so is undef');
};

# PLAYED MOVES. Every move of a batch of games is shown as the engine reports
# it and read back, and the decoration is checked against what the engine said
# happened, not against what this module wrote.
sub shown {
    my ($g, $mv) = @_;
    my ($flags, @squares) = $g->preview($mv);
    my $is_king = $g->at($E->move_from($mv)) == KING;
    my $text = move_display(wire($mv), {
        king       => $is_king,
        captures   => [ map { name($_) } @squares ],
        king_home  => $flags & KING_HOME,
        king_taken => $flags & KING_TAKEN,
    });
    return ($text, $flags, $is_king, scalar @squares);
}

subtest 'five hundred games, every move shown and read back' => sub {
    my $roll = roller(505);
    my ($games, $moves, $bad, %ended, %marks) = (0, 0, 0);
    my ($kings, $captures, $last_bad) = (0, 0, 0);
    for my $i (1 .. 500) {
        my $g = $R->new(variant => { ply_cap => 150 });
        my ($final, $final_flags);
        until ($g->is_over) {
            my @legal = $g->moves;
            my $mv = $legal[ $roll->(scalar @legal) ];
            my ($text, $flags, $is_king, $n) = shown($g, $mv);
            $moves++;
            $bad++ unless defined $text && move_parse($text) eq wire($mv);
            $bad++ if ($text =~ /\AK/) != !!$is_king;
            $bad++ if ($text =~ /x/) != ($n > 0);
            $bad++ if $n && ($text =~ tr/,//) != $n - 1;
            $bad++ if ($text =~ /\+\+\z/) != !!($flags & KING_HOME);
            $bad++ if ($text =~ /#\z/) != !!($flags & KING_TAKEN);
            $kings++ if $is_king;
            $captures++ if $n;
            $marks{plus}++ if $text =~ /\+\+/;
            $marks{hash}++ if $text =~ /#/;
            $g->play($mv);
            ($final, $final_flags) = ($text, $flags);
        }
        $games++;
        my $how = outcome_name($g->outcome);
        $ended{$how}++;
        $last_bad++ if ($how eq 'corner')  != !!($final =~ /\+\+\z/);
        $last_bad++ if ($how eq 'capture') != !!($final =~ /#\z/);
    }
    is($games, 500, 'five hundred games, counted');
    cmp_ok($moves, '>', 20_000, "$moves moves shown");
    cmp_ok($kings, '>', 1000, "$kings of them the king's");
    cmp_ok($captures, '>', 1000, "$captures of them captures");
    is($bad, 0, 'each read back to the move that made it, with K, x, the commas, ++ and # exactly where the engine said');
    is($last_bad, 0, 'a game won by a corner ends on ++ and one won by capture on #, and no other game does');
    is($marks{plus}, $ended{corner}, "++ appears $marks{plus} times: once a game won by a corner, and nowhere else");
    is($marks{hash}, $ended{capture}, "# appears $marks{hash} times: once a game won by capture, and nowhere else");
    cmp_ok($ended{corner} // 0, '>', 50, 'with corners among the endings');
    cmp_ok($ended{capture} // 0, '>', 50, 'and captures');
};

subtest 'a position: the set-up, and its cells' => sub {
    is(SETUP, '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', 'SETUP is the set-up');
    is(SETUP, $E->new->to_string, 'and is what the engine starts from');
    ok(position_ok(SETUP), 'it is a position');

    my ($rows, $side) = position_cells(SETUP);
    is($side, 'a', 'the attackers to move');
    is(scalar(@$rows), 7, 'seven rows');
    is(join('|', map { join(',', map { $_ eq '' ? '.' : $_ } @$_) } @$rows),
        '.,.,.,a,.,.,.|.,.,.,a,.,.,.|.,.,.,d,.,.,.|a,a,d,k,d,a,a|.,.,.,d,.,.,.|.,.,.,a,.,.,.|.,.,.,a,.,.,.',
        'rank 7 first, file a first, each cell what stands there');

    ($rows, $side) = position_cells('k6/7/7/7/7/7/6a d');
    is($rows->[0][0], 'k', 'the first cell of the first row is a7');
    is($rows->[6][6], 'a', 'the last cell of the last row is g1');
    is($side, 'd', 'the defenders to move');
    is_deeply([ position_cells('7/7 a') ], [], 'a string that is not a position has no cells');
};

# THE ENGINE IS THE AUTHORITY on what a position is, and this module must say
# the same without it. Two thousand strings: boards the engine wrote, and the
# same strings with one thing done to them.
subtest 'position_ok agrees with the engine on two thousand strings' => sub {
    my $roll = roller(2000);
    my @alphabet = (split(//, 'adk1234567/ '), 'A', 'x', '8', '0', '.');
    my ($n, $bad, $yes, $no, @first) = (0, 0, 0, 0);
    for my $i (1 .. 1000) {
        my $bd = $E->new(empty => 1);
        my $density = 2 + $roll->(7);
        for my $s ($E->all_squares) {
            my $what = $roll->($density);
            $bd->put($s, $what) if $what >= 1 && $what <= 3;
        }
        $bd->set_side($roll->(2) ? DEFENDERS : ATTACKERS);
        my $good = $bd->to_string;

        my $mangled = $good;
        my $at = $roll->(length $mangled);
        my $how = $roll->(5);
        if    ($how == 0) { substr($mangled, $at, 1) = '' }
        elsif ($how == 1) { substr($mangled, $at, 0) = $alphabet[ $roll->(scalar @alphabet) ] }
        elsif ($how == 2) { substr($mangled, $at, 1) = $alphabet[ $roll->(scalar @alphabet) ] }
        elsif ($how == 3) { $mangled = substr($mangled, 0, $at) }
        else              { $mangled .= $alphabet[ $roll->(scalar @alphabet) ] }

        for my $string ($good, $mangled) {
            my ($board) = $E->of_string($string);
            my $engine = defined $board ? 1 : 0;
            my $here = position_ok($string) ? 1 : 0;
            $n++;
            $engine ? $yes++ : $no++;
            if ($engine != $here) { $bad++; push @first, "'$string': engine $engine, notation $here" if @first < 4 }
        }
    }
    is($n, 2000, 'two thousand strings');
    cmp_ok($yes, '>=', 1000, "$yes the engine takes");
    cmp_ok($no, '>=', 700, "$no it refuses");
    is($bad, 0, 'and this module says the same of every one') or diag(join "\n", @first);

    ok(!position_ok($_), "not a position: '$_'") for '', '7/7/7/7/7/7/7', '7/7/7/7/7/7/7 w', '8/7/7/7/7/7/7 a',
        '7/7/7/7/7/7 a', '7/7/7/7/7/7/7/7 a', '7/7/7/3K3/7/7/7 a', '7/7/7/7/7/7/7  a', '7/7/7/7/7/7/7 a ';
    ok(!position_ok(undef), 'nor is undef');
    ok(!position_ok([]), 'nor a reference');
    ok(position_ok('k5k/7/7/7/7/7/7 a'), 'two kings is written correctly, and that is all that is asked');
};

subtest 'a game as text' => sub {
    is(game_string({ variant => 'brandubh', moves => [qw(d1c1 d3c3 c1d1)] }),
        "variant brandubh\nmoves d1c1 d3c3 c1d1\n", 'from the set-up: two lines');
    is(game_string({ moves => [] }), "variant brandubh\nmoves\n", 'no moves yet, and the variant defaults');
    is(game_string({ variant => 'brandubh', start => SETUP, moves => ['d1c1'] }),
        "variant brandubh\nmoves d1c1\n", 'a start that is the set-up is left out');
    is(game_string({ variant => 'custom repeat=2', start => '7/7/7/3k3/7/7/a6 d', moves => [qw(d4d1 a1a2)] }),
        "variant custom repeat=2\nstart 7/7/7/3k3/7/7/a6 d\nmoves d4d1 a1a2\n", 'a start that is not: three lines');
    is(game_string({ moves => ['d1c1'], result => { how => 'resign', by => 'attackers' } }),
        "variant brandubh\nmoves d1c1\nresult resign attackers\n", 'a resignation is a fourth line');
    is(game_string({ moves => ['d1c1'], result => { how => 'agreed' } }),
        "variant brandubh\nmoves d1c1\nresult agreed\n", 'and so is an agreed draw');

    is(game_string({ moves => ['d1-c1'] }), undef, 'a move that is not a stored move: undef');
    is(game_string({ moves => ['d1c1'], start => '7/7 a' }), undef, 'a start that is not a position: undef');
    is(game_string({ moves => ['d1c1'], result => { how => 'resign' } }), undef, 'a resignation by nobody: undef');
    is(game_string({ moves => ['d1c1'], result => { how => 'corner' } }), undef, 'a result the board can show for itself: undef');
    is(game_string({ moves => ['d1c1'], result => 'agreed' }), undef, 'a result that is not a hash: undef');
    is(game_string({ variant => "two\nlines", moves => [] }), undef, 'a variant with a line break in it: undef');
    is(game_string('moves d1c1'), undef, 'and a string is not a game');
};

subtest 'a resignation is never written among the moves' => sub {
    my $text = game_string({ moves => [qw(d1c1 d3c3)], result => { how => 'resign', by => 'defenders' } });
    my ($moves) = $text =~ /^moves (.*)$/m;
    is($moves, 'd1c1 d3c3', 'the moves line holds the moves and nothing else');
    is(scalar(split ' ', $moves), 2, 'two of them');
    is_deeply(game_parse($text)->{moves}, [qw(d1c1 d3c3)], 'and they parse back as two');
};

subtest 'game_parse' => sub {
    is_deeply(game_parse("variant brandubh\nmoves d1c1 d3c3\n"),
        { variant => 'brandubh', start => SETUP, moves => [qw(d1c1 d3c3)], result => undef },
        'a game from the set-up: the start is filled in');
    is_deeply(game_parse("variant brandubh\nstart 7/7/7/3k3/7/7/a6 d\nmoves d4d1\nresult agreed\n"),
        { variant => 'brandubh', start => '7/7/7/3k3/7/7/a6 d', moves => ['d4d1'], result => { how => 'agreed' } },
        'all four lines');
    is_deeply(game_parse("variant brandubh\r\nmoves d1c1\r\n")->{moves}, ['d1c1'], 'line endings from another system');
    is_deeply(game_parse("\nvariant brandubh\n\nmoves\n\n")->{moves}, [], 'blank lines, and no moves');
    is_deeply(game_parse("moves d1c1\nvariant brandubh\n")->{moves}, ['d1c1'], 'the lines in another order');

    my @not = (
        [ "moves d1c1\n",                                    'no variant line' ],
        [ "variant brandubh\n",                              'no moves line' ],
        [ "variant brandubh\nmoves d1c1\nmoves d3c3\n",      'a line given twice' ],
        [ "variant brandubh\nmoves d1-c1\n",                 'a move as it is shown, not as it is stored' ],
        [ "variant brandubh\nmoves d1c1 resign\n",           'a resignation among the moves' ],
        [ "variant brandubh\nstart 7/7 a\nmoves\n",          'a start that is not a position' ],
        [ "variant brandubh\nmoves\nresult resign\n",        'a resignation by nobody' ],
        [ "variant brandubh\nmoves\nresult corner\n",        'a result that is not one' ],
        [ "variant brandubh\nmoves\nclock 5m\n",             'a line it does not know' ],
        [ "variant\nmoves\n",                                'a variant line with no variant' ],
        [ '',                                                'nothing at all' ],
    );
    for my $case (@not) {
        is(game_parse($case->[0]), undef, "not a game: $case->[1]");
    }
    is(game_parse(undef), undef, 'nor is undef');
    is(game_parse({}), undef, 'nor a reference');
};

# A hundred games written and read back: from the set-up and from elsewhere,
# finished on the board, resigned, agreed, and one with no move in it.
subtest 'a hundred games round-trip, and replay to the same position' => sub {
    my $roll = roller(100);
    my ($bad, $replayed, %kinds) = (0, 0);
    my @starts = (SETUP, '7/7/7/3k3/7/7/a6 d', '7/d3a2/7/7/2ad3/6k/7 a', '7/7/2a4/7/7/7/1k5 a');
    for my $i (1 .. 100) {
        my $start = $i % 3 == 0 ? $starts[ 1 + $roll->(3) ] : SETUP;
        my $variant = $i % 4 == 0 ? 'custom repeat=2,ply_cap=60' : 'brandubh';
        my $g = $R->new(position => $start, variant => { ply_cap => 60 });
        my @moves;
        my $length = $i == 1 ? 0 : 1 + $roll->(40);
        while (@moves < $length && !$g->is_over) {
            my @legal = $g->moves;
            my $mv = $legal[ $roll->(scalar @legal) ];
            push @moves, wire($mv);
            $g->play($mv);
        }
        my $result = $g->is_over ? undef
                   : $i % 5 == 0 ? { how => 'resign', by => ($i % 2 ? 'attackers' : 'defenders') }
                   : $i % 7 == 0 ? { how => 'agreed' }
                   : undef;
        $kinds{ $result ? $result->{how} : $g->is_over ? 'on the board' : 'unfinished' }++;
        $kinds{elsewhere}++ if $start ne SETUP;

        my $record = { variant => $variant, start => $start, moves => \@moves, result => $result };
        my $text = game_string($record);
        my $back = defined $text ? game_parse($text) : undef;
        if (!$back) { $bad++; next }
        $bad++ unless $back->{variant} eq $variant && $back->{start} eq $start
                   && "@{ $back->{moves} }" eq "@moves";
        $bad++ unless (defined $result ? join(' ', map { "$_=$result->{$_}" } sort keys %$result) : 'none')
                   eq (defined $back->{result} ? join(' ', map { "$_=$back->{result}{$_}" } sort keys %{ $back->{result} }) : 'none');
        $bad++ unless game_string($back) eq $text;

        my $again = $R->new(position => $back->{start}, variant => { ply_cap => 60 });
        my $refused = grep { $again->play(unwire($_)) != PLAY_OK } @{ $back->{moves} };
        $bad++ if $refused || $again->position ne $g->position;
        $replayed++;
    }
    is($replayed, 100, 'a hundred games written, read, and played again from what was read');
    is($bad, 0, 'each came back the same, text and position');
    cmp_ok($kinds{$_} // 0, '>=', 1, "among them: $_ ($kinds{$_})")
        for 'resign', 'agreed', 'on the board', 'unfinished', 'elsewhere';
};

is(scalar(@warnings), 0, 'and through all of it, not one warning') or diag(@warnings);

done_testing();
