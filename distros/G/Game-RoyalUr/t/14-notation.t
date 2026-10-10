use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Notation ':all';
use Game::RoyalUr::Engine ();
use Game::RoyalUr::Dice qw(throw_for marked roll_of);
my $E = 'Game::RoyalUr::Engine';

my %RULES = (
    finkel  => { dice => 4, zero_rolls => 0 },
    masters => { dice => 3, zero_rolls => 4 },
);

subtest 'the twenty squares' => sub {
    my @ok = grep { square_ok($_) } map { my $f = $_; map { "$f$_" } 1 .. 3 } 'a' .. 'h';
    is(scalar @ok, 20, 'twenty names are squares');
    ok(!square_ok($_), "$_ is not one") for qw(e1 f1 e3 f3 i1 a0 a4 A1 hand home), '', 'a11';
    ok(!square_ok(undef), 'nor is undef');
    is_deeply([ sort @ok ], [ sort map { $E->cell_name($_) } $E->all_cells ], 'and they are the engine\'s twenty');
};

subtest 'a wire move, read' => sub {
    is_deeply([ parse_move('hand-b1') ], [ { from => 'hand', to => 'b1' }, undef ], 'hand-b1');
    is_deeply([ parse_move('b1-b2') ],   [ { from => 'b1',   to => 'b2' }, undef ], 'b1-b2');
    is_deeply([ parse_move('g1-home') ], [ { from => 'g1',   to => 'home' }, undef ], 'g1-home');
    is_deeply([ parse_move('hand-home') ], [ { from => 'hand', to => 'home' }, undef ],
        'hand-home reads: whether any roll allows it is not this module\'s question');
    is_deeply([ parse_move('b1-h3') ], [ { from => 'b1', to => 'h3' }, undef ], 'and so does b1-h3');

    is_deeply([ parse_move('HAND-B1') ], [ { from => 'hand', to => 'b1' }, undef ], 'capitals are read');
    is_deeply([ parse_move('G1-Home') ], [ { from => 'g1', to => 'home' }, undef ], 'in either word');
};

# EACH REFUSAL from a string written to produce it.
subtest 'a wire move, refused' => sub {
    my @cases = (
        [ '',          'empty',     'an empty string' ],
        [ 'b1',        'shape',     'one place' ],
        [ 'a1-b1-c1',  'shape',     'three places' ],
        [ 'b1b2',      'shape',     'no dash' ],
        [ 'hand-hand', 'to_hand',   'hand to hand' ],
        [ 'b1-hand',   'to_hand',   'a square to the hand' ],
        [ 'home-b1',   'from_home', 'home to a square' ],
        [ 'e1-d1',     'place',     'a square that does not exist' ],
        [ 'i2-a1',     'place',     'a file past h' ],
        [ 'b0-b1',     'place',     'a row below 1' ],
        [ 'b1-b4',     'place',     'a row above 3' ],
        [ 'b1-b2x',    'place',     'a trailing x' ],
        [ 'b1-b2*',    'place',     'a trailing star' ],
        [ ' b1-b2',    'place',     'a leading space' ],
        [ 'b1-b2 ',    'place',     'a trailing space' ],
        [ 'b1>b2',     'shape',     'another separator' ],
        [ 'b1-',       'place',     'nowhere to go' ],
        [ 'b11-b2',    'place',     'a square with two digits' ],
    );
    for my $case (@cases) {
        my ($text, $want, $what) = @$case;
        my ($move, $error) = parse_move($text);
        ok(!defined $move, "$what: no move");
        is($error, $want, "$what: $want");
    }
    is((parse_move(undef))[1], 'empty', 'undef is empty');
};

subtest 'a move, written' => sub {
    is(format_move({ from => 'hand', to => 'b1' }), 'hand-b1', 'from a hash');
    is(format_display({ from => 'b1', to => 'b2', roll => 3 }), '3: b1-b2', 'a plain move');
    is(format_display({ from => 'a2', to => 'c2', roll => 2, captures => 1 }), '2: a2-c2x', 'a capture');
    is(format_display({ from => 'hand', to => 'a1', roll => 4, rosette => 1 }), '4: hand-a1*', 'a rosette');
    is(format_display({ from => 'a2', to => 'd2', roll => 3, captures => 1, rosette => 1 }), '3: a2-d2x*',
        'a capture on a rosette: x and then the star');
    is(format_display({ from => 'g1', to => 'home', roll => 1 }), '1: g1-home', 'a piece going home');
    is(format_display({ from => 'b1', to => 'b2', roll => 3 }, 9), '9: b1-b2', 'a roll given beside the move wins');
    is(format_forfeit(0), '0: -', 'a turn lost to a roll of nothing');
    is(format_forfeit(3), '3: -', 'and to a roll of 3 with nowhere to go');
};

# Two thousand positions a rule set, reached by playing, and every move the
# generator offers in each: written, read back, and the same.
subtest 'every move the generator makes goes out and comes back' => sub {
    for my $rules ('finkel', 'masters') {
        srand(20261009);
        my $spelled = $E->rules($rules);
        my @rolls = map { $_->[0] } $E->chances($spelled->{dice}, $spelled->{zero_rolls});
        my ($positions, $moves, %shapes, @bad) = (0, 0);
        while ($positions < 2_000) {
            my $bd = $E->new;
            while ($bd->status($rules) == 0 && $positions < 2_000) {
                $positions++;
                my @chosen;
                for my $roll (@rolls) {
                    my @list = $bd->moves($roll, $rules);
                    for my $move (@list) {
                        $moves++;
                        my $wire = format_move($move);
                        my ($back, $error) = parse_move($wire);
                        push @bad, "$wire did not read: $error" unless $back;
                        push @bad, "$wire came back different"
                            unless $back && $back->{from} eq $move->from && $back->{to} eq $move->to;
                        my $shown = format_display($move);
                        push @bad, "$shown is not the display of $wire"
                            unless $shown eq $move->roll . ": $wire" . ($move->captures ? 'x' : '') . ($move->rosette ? '*' : '');
                        $shapes{ ($move->captures ? 'x' : '') . ($move->rosette ? '*' : '') }++;
                    }
                    push @chosen, $list[ rand @list ] if @list;
                }
                if (@chosen) { $bd->apply($chosen[ rand @chosen ], $rules) } else { $bd->forfeit }
            }
        }
        is(scalar @bad, 0, "$rules: $moves moves from $positions positions") or diag(join "\n", @bad[0 .. 4]);
        ok($shapes{$_}, "$rules: among them the shape '$_'") for '', 'x', '*';
    }
};

subtest 'validate_position agrees with the engine' => sub {
    is(POS_OK, Game::RoyalUr::Engine::POS_OK, 'the codes are the engine\'s: OK');
    is(POS_LONG, Game::RoyalUr::Engine::POS_LONG, 'and LONG, at the other end');
    is(POS_GAP, Game::RoyalUr::Engine::POS_GAP, 'and GAP in the middle');

    my @bad = (
        '', '4xx2/8 l 7 0 7 0', '4xx2/8/4xx2/8 l 7 0 7 0', '4xx1/8/4xx2 l 7 0 7 0', '4xx2/8l/4xx2 l 7 0 7 0',
        '4xx2/8/4xx3 l 7 0 7 0', '4xx2/7/4xx2 l 7 0 7 0', '4xx2/3k4/4xx2 l 7 0 7 0', '4xx2/9/4xx2 l 7 0 7 0',
        '4xx2/L7/4xx2 l 7 0 7 0', '4lx2/8/4xx2 l 6 0 7 0', '4xx2/8/4xd2 l 7 0 6 0', '8/8/4xx2 l 7 0 7 0',
        '4xx2/8/5x2 l 7 0 7 0', '4xx2/4x3/4xx2 l 7 0 7 0', 'x3xx2/8/4xx2 l 7 0 7 0', '4xx2/8/4xx2 w 7 0 7 0',
        '4xx2/8/4xx2 7 0 7 0', '4xx2/8/4xx2 l 8 0 7 0', '4xx2/8/4xx2 l 7 0 7 12', '4xx2/8/4xx2 l 7 a 7 0',
        '4xx2/8/4xx2 l -1 0 7 0', '4xx2/8/4xx2', '4xx2/8/4xx2 l', '4xx2/8/4xx2 l 7 0', '4xx2/8/4xx2 l 7 0 7',
        '4xx2/8/4xx2 l 7 0 7 0 0', '4xx2/8/4xx2 l 7 0 7 0 ', '4xx2/8/4xx2 l7 0 7 0',
        '4xx2/8/4xx2 l 7 0 7 0' . (' ' x 30), '/8/4xx2 l 7 0 7 0', '4xx2//4xx2 l 7 0 7 0', '4xx2/8/ l 7 0 7 0',
        ' 4xx2/8/4xx2 l 7 0 7 0', '4xx2/8/4xx2  l 7 0 7 0', '4xx2/8/4xx2 l  7 0 7 0', '4xx2/8/4xx2 d 7 0 7 x',
        '4xx2/0/4xx2 l 7 0 7 0', 'xxxxxxxx/8/4xx2 l 7 0 7 0', '4xx2/8/4x3 l 7 0 7 0', '4xx2/8/xx6 l 7 0 7 0',
        '44/8/4xx2 l 7 0 7 0', '4xx2/8/4xx2 l 7 0 7 0/', '4xx2/8/4xx2 ld 7 0 7 0', '4xx2/8/4xx2 l 77 0 7 0',
        'l', '/', '//', ' ', 'x', '8', '4xx2', '4xx2/8/4xx2 ', '4xx2/8/4xx2 l ', '4xx2/8/4xx2 l 7 ',
        '4xx2/88/4xx2 l 7 0 7 0', '4xx2/l8/4xx2 l 7 0 7 0', '4xx2/8/4xx2 l 7 0 7 0x', '4xx2/8/4xx2 L 7 0 7 0',
        '4XX2/8/4xx2 l 7 0 7 0',
    );
    cmp_ok(scalar @bad, '>=', 60, scalar(@bad) . ' strings that are not positions');
    my (@differ, %codes);
    for my $string (@bad) {
        my (undef, $engine) = $E->of_string($string);
        my $here = validate_position($string);
        $codes{$here}++;
        push @differ, "'$string': here $here, the engine $engine" unless $here == $engine;
        push @differ, "'$string' is accepted" if $here == POS_OK;
    }
    is(scalar @differ, 0, 'the same code for every one, and never OK') or diag(join "\n", @differ);
    is(scalar(keys %codes), 10, 'and all ten codes among them');
    is(validate_position(undef), POS_NULL, 'undef is no string');

    srand(20261009);
    my @wrong;
    for my $n (1 .. 500) {
        my $bd = $E->new;
        $bd->put($_, int rand 3) for $E->all_cells;
        $bd->set_side(int rand 2);
        $bd->set_hand($_, int rand 8)->set_home($_, int rand 8) for 0, 1;
        my $string = $bd->to_string;
        push @wrong, $string unless validate_position($string) == POS_OK;
    }
    is(scalar @wrong, 0, 'and five hundred strings the engine wrote are all OK');
};

# A record, built here. With a seed, its rolls are the seed's.
sub record_for {
    my ($rules, $seed_hex, @moves) = @_;
    my $bytes = pack 'H*', $seed_hex;
    my (@turns, $n) = ();
    my $side = 'light';
    for my $move (@moves) {
        my $throw = throw_for($bytes, $n++ // 0, $RULES{$rules}{dice});
        my %turn = (side => $side, roll => roll_of(marked($throw), $RULES{$rules}), move => $move);
        push @turns, \%turn;
        my $rosette = defined $move && $move =~ /-(?:a1|g1|a3|g3|d2)\z/;
        $side = ($side eq 'light' ? 'dark' : 'light') unless $rosette;
    }
    return { rules => $rules, first => 'light', seed => $seed_hex, turns => \@turns };
}

subtest 'a record, written and read' => sub {
    my $record = {
        rules => 'finkel', first => 'light',
        turns => [
            { side => 'light', roll => 3, move => 'hand-b1' },
            { side => 'dark',  roll => 0, move => undef },
            { side => 'light', roll => 4, faces => '1111', move => 'hand-a1' },
            { side => 'light', roll => 1, move => 'b1-a2' },
        ],
        result => { winner => 'dark', how => 'resign' },
    };
    my $text = format_record($record);
    is($text, <<'RECORD', 'the text, literally');
[rules finkel]
[first light]
1. l 3: hand-b1
2. d 0: -
3. l 4 1111: hand-a1
4. l 1: b1-a2
[result dark resign]
RECORD
    my ($back, $problem) = parse_record($text);
    ok($back, 'it reads') or diag(explain $problem);
    is_deeply($back, $record, 'to the record it was written from');
    is(format_record($back), $text, 'and writes the same bytes again');
};

subtest 'three whole records round-trip byte for byte' => sub {
    my @texts = (
        format_record(record_for('finkel',  '5f1c9a', 'hand-d1', 'hand-d3', undef, 'hand-c3')),
        format_record(record_for('masters', '00ff10', 'hand-d1', 'hand-d3', 'd1-c1', 'd3-c3')),
        "[rules route=long dice=4 zero_rolls=0 safe_rosettes=1 pieces=5]\n[first dark]\n"
            . "1. d 4: hand-a3\n2. d 4: a3-d2\n3. d 2: hand-c3\n4. l 0: -\n[result draw ply_cap]\n",
    );
    for my $text (@texts) {
        my ($record, $problem) = parse_record($text);
        ok($record, 'the record reads') or diag($text, explain $problem);
        is(format_record($record), $text, 'and comes back the same bytes') if $record;
    }
    my ($spelled) = parse_record($texts[2]);
    is_deeply($spelled->{rules}, { route => 'long', dice => 4, zero_rolls => 0, safe_rosettes => 1, pieces => 5 },
        'a rule set that is spelled out is read as its five fields');
    is($spelled->{first}, 'dark', 'and dark may move first');
};

# WITH A SEED THE ROLLS ARE CHECKED. The record below is right; then one roll
# is edited and nothing else.
subtest 'a record with a seed must throw what the seed throws' => sub {
    my $record = record_for('finkel', '5f1c9a', 'hand-d1', 'hand-d3', 'd1-c1', 'd3-c3', 'c1-b1');
    my $text = format_record($record);
    my ($ok) = parse_record($text);
    ok($ok, 'the record as it was thrown reads');

    my @lines = split /\n/, $text;
    my ($roll) = $lines[5] =~ /\A3\. [ld] ([0-4]):/ or die "line 6 is not turn 3: $lines[5]";
    my $other = ($roll + 1) % 5;
    (my $edited = $text) =~ s/^3\. ([ld]) $roll:/3. $1 $other:/m;
    isnt($edited, $text, "turn 3's roll edited from $roll to $other");
    my ($none, $problem) = parse_record($edited);
    ok(!$none, 'the edited record is refused');
    is($problem->{line}, 6, 'at line 6, which is turn 3');
    is($problem->{error}, 'roll', 'because of the roll');

    (my $unseeded = $edited) =~ s/^\[seed [0-9a-f]+\]\n//m;
    my ($taken) = parse_record($unseeded);
    ok($taken, 'the same edited record WITHOUT its seed is accepted: the rolls are taken as written');
    is($taken->{turns}[2]{roll}, $other, 'with the roll it says');

    my $with_opening = "[rules finkel]\n[first dark]\n[seed 5f1c9a]\n[opening 2]\n";
    my $third = roll_of(marked(throw_for(pack('H*', '5f1c9a'), 2, 4)), $RULES{finkel});
    my ($opened, $why) = parse_record($with_opening . "1. d $third: " . ($third ? 'hand-d3' : '-') . "\n");
    ok($opened, 'after an opening of two throws the first turn is throw 2') or diag(explain $why);
    is($opened->{opening}, 2, 'and the record says so');
};

subtest 'the dice written on a line are checked too' => sub {
    my $head = "[rules finkel]\n[first light]\n";
    ok((parse_record($head . "1. l 3 1011: hand-b1\n"))[0], 'three marked is a roll of 3');
    is((parse_record($head . "1. l 2 1011: hand-c1\n"))[1]{error}, 'faces', 'three marked is not a roll of 2');
    is((parse_record($head . "1. l 3 101: hand-b1\n"))[1]{error}, 'faces', 'finkel has four dice, not three');
    my $masters = "[rules masters]\n[first light]\n";
    ok((parse_record($masters . "1. l 4 000: hand-a1\n"))[0], 'under masters nothing marked is a roll of 4');
    is((parse_record($masters . "1. l 0 000: -\n"))[1]{error}, 'faces', 'and is not a roll of 0');

    my $bytes = pack 'H*', '5f1c9a';
    my $faces = join '', @{ throw_for($bytes, 0, 4) };
    my $roll = roll_of(marked(throw_for($bytes, 0, 4)), $RULES{finkel});
    my $move = $roll ? 'hand-' . (qw(x d1 c1 b1 a1))[$roll] : '-';
    ok((parse_record("[rules finkel]\n[first light]\n[seed 5f1c9a]\n1. l $roll $faces: $move\n"))[0],
        'with a seed, the faces the seed throws are accepted');
    is($faces, '1001', '(that seed opens with 1001, a roll of 2: if this fails the dice changed, not the notation)');
    is((parse_record("[rules finkel]\n[first light]\n[seed 5f1c9a]\n1. l 2 0110: hand-c1\n"))[1]{error},
        'faces', 'and OTHER faces worth the same roll are refused');
};

# THE SIDE IS ON EVERY LINE AND IT IS CHECKED. After a move onto a rosette the
# same side moves again.
subtest 'the side letters must follow from the moves' => sub {
    my $head = "[rules finkel]\n[first light]\n";
    ok((parse_record($head . "1. l 4: hand-a1\n2. l 2: hand-c1\n3. d 1: hand-d3\n"))[0],
        'light, light again after the rosette, then dark');
    my (undef, $problem) = parse_record($head . "1. l 4: hand-a1\n2. d 2: hand-c3\n");
    is($problem->{error}, 'side', 'dark on the line after a rosette is refused');
    is($problem->{line}, 4, 'at that line');
    is((parse_record($head . "1. l 3: hand-b1\n2. l 2: hand-c1\n"))[1]{error}, 'side',
        'and light twice running with no rosette is refused');
    is((parse_record($head . "1. l 0: -\n2. l 2: hand-c1\n"))[1]{error}, 'side', 'a forfeit passes the turn');
    is((parse_record($head . "1. d 3: hand-b3\n"))[1]{error}, 'side', 'and the first line is the side named first');
    ok((parse_record("[rules masters]\n[first light]\n1. l 1: g2-g3\n2. l 4: g3-g1\n3. l 1: g1-home\n4. d 2: hand-c3\n"))[0],
        'the far rosette keeps the turn, and going home passes it');
};

subtest 'what else a record is refused for' => sub {
    my $head = "[rules finkel]\n[first light]\n";
    my @cases = (
        [ '',                                              0, 'empty',        'nothing' ],
        [ $head . '1. l 3: hand-b1',                       0, 'no_newline',   'no newline at the end' ],
        [ "[first light]\n",                               1, 'rules',        'no rules' ],
        [ "[rules bell]\n[first light]\n",                 1, 'rules',        'a rule set that is none' ],
        [ "[rules dice=4 route=short zero_rolls=0 safe_rosettes=1 pieces=7]\n[first light]\n", 1, 'rules', 'fields out of order' ],
        [ "[rules route=short dice=5 zero_rolls=0 safe_rosettes=1 pieces=7]\n[first light]\n", 1, 'rules', 'five dice' ],
        [ "[rules finkel]\n1. l 3: hand-b1\n",             2, 'first',        'no first' ],
        [ "[rules finkel]\n[first white]\n",               2, 'first',        'a first that is neither' ],
        [ $head . "[opening 2]\n",                         3, 'opening',      'an opening with no seed' ],
        [ $head . "[seed 5f1c9a]\n[opening 3]\n",          4, 'opening',      'an odd opening' ],
        [ $head . "2. l 3: hand-b1\n",                     3, 'number',       'a game that starts at turn 2' ],
        [ $head . "1. l 3: hand-b1\n3. d 1: hand-d3\n",    4, 'number',       'a turn number skipped' ],
        [ $head . "1. l 5: hand-b1\n",                     3, 'turn',         'a roll of 5' ],
        [ $head . "1. l 3: e1-d1\n",                       3, 'move',         'a square that does not exist' ],
        [ $head . "1. l 3: HAND-b1\n",                     3, 'move',         'a move not in lower case' ],
        [ $head . "1. l 3: hand-b1x\n",                    3, 'move',         'a display mark on a record line' ],
        [ $head . "1. l 3 hand-b1\n",                      3, 'turn',         'no colon' ],
        [ $head . "\n1. l 3: hand-b1\n",                   3, 'turn',         'a blank line' ],
        [ $head . "1. l 3: hand-b1\n[result light won]\n", 4, 'result',       'a result that is none' ],
        [ $head . "1. l 3: hand-b1\n[result draw home]\n", 4, 'result',       'a draw by home' ],
        [ $head . "[result light resign]\n1. l 3: hand-b1\n", 4, 'after_result', 'a turn after the result' ],
    );
    for my $case (@cases) {
        my ($text, $line, $error, $what) = @$case;
        my ($record, $problem) = parse_record($text);
        ok(!$record, "$what: refused");
        is(($problem || {})->{error}, $error, "$what: $error");
        is(($problem || {})->{line}, $line, "$what: at line $line");
    }
};

done_testing();
