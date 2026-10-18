use strict;
use warnings;
use Test::More;

use Game::Senet::Notation ':all';
use Game::Senet::Engine ();
use Game::Senet::Rules;
use Game::Senet::Sticks qw(throw_for roll_for light_of extra_throw);

my $E = 'Game::Senet::Engine';

# ---- moves ------------------------------------------------------------------

subtest 'every move the generator makes writes and reads back' => sub {
    srand(5);
    my ($n, @bad) = (0);
    for my $set (qw(kendall skyruk)) {
        for (1 .. 1_000) {
            my $bd = $E->new(pieces => 7);
            for my $side (0, 1) {
                my $want = int(rand(8));
                while ($want) {
                    my $h = 1 + int(rand(30));
                    next if $bd->at($h);
                    $bd->put($h, $side + 1);
                    $want--;
                }
            }
            $bd->set_side(int(rand(2)));
            for my $roll (1 .. 5) {
                for my $m ($bd->moves($roll, { exits => $set, pieces => 7 })) {
                    my $text = format_move($m);
                    my ($back, $why) = parse_move($text);
                    $n++;
                    push @bad, "$text ($why)" and next unless $back;
                    push @bad, $text unless format_move($back) eq $text
                        && $back->{from} == $m->from && "$back->{to}" eq ($m->off ? 'off' : $m->to);
                }
            }
        }
    }
    cmp_ok($n, '>', 20_000, "$n moves, exits and bear-offs among them");
    is("@bad", '', 'each wrote and read back to itself');
};

subtest 'each refusal' => sub {
    my @cases = (
        [ '',          'empty' ],
        [ undef,       'empty' ],
        [ '12',        'shape' ],
        [ '12-15-18',  'long' ],
        [ '1-2-3',     'shape' ],
        [ '0-5',       'house' ],
        [ '12-31',     'house' ],
        [ '012-15',    'house' ],
        [ '12-12',     'same' ],
        [ 'off-12',    'from_off' ],
        [ '12-15<',    'shape' ],
        [ '12-15x',    'shape' ],
        [ ' 12-15',    'shape' ],
        [ '12->15',    'shape' ],
        [ '-15',       'shape' ],
        [ '26-off+x',  'long' ],
    );
    for my $case (@cases) {
        my ($text, $why) = @$case;
        my ($move, $got) = parse_move($text);
        ok(!$move, 'refused: ' . ($text // 'undef'));
        is($got, $why, "  as $why");
    }
    ok((parse_move('3-29'))[0], 'a move no board allows still parses: legality is the game\'s');
};

subtest 'off in any case' => sub {
    for my $off (qw(off OFF Off oFf)) {
        my ($m) = parse_move("26-$off");
        is($m->{to}, 'off', "26-$off reads as off");
        is(format_move($m), '26-off', 'and is written lower case');
    }
};

subtest 'the display form, as literal strings' => sub {
    my %m = (
        plain    => { from => 12, to => 15, roll => 3 },
        swap     => { from => 1,  to => 5,  roll => 4, swap => 1 },
        back     => { from => 22, to => 17, roll => 5, back => 1 },
        backswap => { from => 22, to => 20, roll => 2, back => 1, swap => 1 },
        walk     => { from => 26, to => 15, roll => 1, walk => 1 },
        off      => { from => 26, to => -1, roll => 5, off => 1 },
    );
    my %want = (
        plain    => [ '3: 12-15',    '3: 12-15+' ],
        swap     => [ '4: 1-5x',     '4: 1-5x+' ],
        back     => [ '5: 22-17<',   '5: 22-17<+' ],
        backswap => [ '2: 22-20<x',  '2: 22-20<x+' ],
        walk     => [ '1: 26-15',    '1: 26-15+' ],
        off      => [ '5: 26-off',   '5: 26-off+' ],
    );
    for my $k (sort keys %m) {
        is(format_display($m{$k}, 0), $want{$k}[0], "$k");
        is(format_display($m{$k}, 1), $want{$k}[1], "$k, and another throw");
    }
    is(format_forfeit(3, 0), '3: -',  'a forfeit that passes the turn');
    is(format_forfeit(4, 1), '4: -+', 'a forfeit that keeps it');
    my ($real) = $E->new(position => '........../.........d/.l.l.d.... l 5')->moves(2, 'kendall');
    is(format_display($real, 0), '2: 22-20<x', 'and from a real Game::Senet::Move');
};

# ---- records -------------------------------------------------------------------

my %VARIANT = (
    kendall => '[variant kendall pieces=5 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0]',
    skyruk  => '[variant skyruk pieces=5 blockade=2 protect=ends backward=1 reach26=any throw_on_26=1]',
    seven   => '[variant kendall pieces=7 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0]',
);

sub play_record {
    my ($set, $seed, $plies, $pieces) = @_;
    my $rules = $pieces ? { exits => $set, pieces => $pieces } : $set;
    my $g = Game::Senet::Rules->new(rules => $rules);
    my $text = ($pieces ? $VARIANT{seven} : $VARIANT{$set}) . "\n[first light]\n[seed " . unpack('H*', $seed) . "]\n";
    srand(length $seed);
    for my $n (1 .. $plies) {
        last if $g->is_over;
        my $sticks = throw_for($seed, $n - 1);
        my $roll = roll_for($seed, $n - 1);
        my $side = substr($g->side, 0, 1);
        my @ms = $g->moves($roll);
        my $move = '-';
        if (@ms) {
            my $m = $ms[ int(rand(@ms)) ];
            $move = format_move($m);
            $g->apply($m);
        }
        else {
            $g->forfeit($roll);
        }
        $text .= "$n. $side $roll " . join('', @$sticks) . ": $move\n";
    }
    $text .= '[result ' . $g->winner . " home]\n" if $g->is_over && $g->how eq 'home';
    return $text;
}

subtest 'the example in the POD' => sub {
    my $text = join "\n", $VARIANT{kendall}, '[first light]',
        '1. l 1: 10-11', '2. l 2: 11-13', '3. d 3: 9-12', '4. l 5 0000: 6-11', '5. l 3: 2-5', '6. d 2: 7-9', '';
    my ($r, $p) = parse_record($text);
    ok($r, 'it reads') or diag(explain $p);
    is(scalar @{ $r->{plies} }, 6, 'six plies');
    is(format_record($r), $text, 'and writes back byte for byte');
};

subtest 'three whole records round-trip, one a set and one of seven pieces' => sub {
    for my $case ([ 'kendall', 'senet record one', 0 ], [ 'skyruk', 'senet record two', 0 ],
                  [ 'kendall', "senet record \x00\xff", 7 ]) {
        my ($set, $seed, $pieces) = @$case;
        my $text = play_record($set, $seed, 2_000, $pieces);
        my ($r, $p) = parse_record($text);
        ok($r, "$set" . ($pieces ? ", $pieces pieces" : '') . ': a played game reads, every roll checked against its seed')
            or diag(explain $p);
        like($text, qr/\[result (?:light|dark) home\]\n\z/, '  played to the end');
        is(format_record($r), $text, '  and writes back byte for byte');
    }
};

subtest 'a roll that is not the seed\'s' => sub {
    my $text = play_record('kendall', 'senet record one', 6);
    my @lines = split /\n/, $text;
    my ($r, $roll) = $lines[5] =~ /\A(3\. [ld] )([1-5])/;
    my $other = { 1 => 4, 4 => 1, 5 => 1, 2 => 3, 3 => 2 }->{$roll};
    (my $edited = $text) =~ s/^3\. ([ld]) $roll \d{4}: /3. $1 $other: /m;
    my ($rec, $p) = parse_record($edited);
    ok(!$rec, 'the third roll edited is refused');
    is_deeply($p, { line => 6, error => 'roll' }, 'at the third ply, line 6, as a roll');
    (my $unseeded = $edited) =~ s/^\[seed [0-9a-f]+\]\n//m;
    my ($ok, $why) = parse_record($unseeded);
    ok($ok, 'without the seed the same record is accepted: the roll is taken as given')
        or diag(explain $why);
};

subtest 'sticks worth another roll' => sub {
    my $text = "$VARIANT{kendall}\n[first light]\n1. l 3 1100: 10-13\n";
    is_deeply((parse_record($text))[1], { line => 3, error => 'sticks' }, 'two light faces are a 2, not a 3');
    $text = "$VARIANT{kendall}\n[first light]\n1. l 5 0000: 10-15\n";
    ok((parse_record($text))[0], 'and four dark faces are a 5');
};

subtest 'the side letter is checked, not trusted' => sub {
    my $after2 = "$VARIANT{kendall}\n[first light]\n1. l 2: 10-12\n2. l 1: 12-13\n";
    is_deeply((parse_record($after2))[1], { line => 4, error => 'side' }, 'light again after a 2 is refused');
    my $after4 = "$VARIANT{kendall}\n[first light]\n1. l 4: 10-14\n2. d 1: 9-10\n";
    is_deeply((parse_record($after4))[1], { line => 4, error => 'side' }, 'dark after a 4 is refused');
    my $forfeit = "$VARIANT{kendall}\n[first light]\n1. l 4: -\n2. l 2: -\n3. d 3: 9-12\n";
    ok((parse_record($forfeit))[0], 'a forfeit on a 4 keeps the side, on a 2 passes it');
    is_deeply((parse_record("$VARIANT{kendall}\n[first dark]\n1. l 2: 10-12\n"))[1], { line => 3, error => 'side' },
        'and the first line is first\'s side');
};

subtest 'throw_on_26 in the header decides the side after 25-26' => sub {
    my $body = "[first light]\n1. l 2: 25-26\n2. l 3: 26-29\n";
    ok((parse_record("$VARIANT{skyruk}\n$body"))[0], 'throw_on_26=1: light throws again after 25-26 on a 2');
    is_deeply((parse_record("$VARIANT{kendall}\n$body"))[1], { line => 4, error => 'side' },
        'throw_on_26=0: refused');
};

subtest 'the header' => sub {
    my $reorder = "[variant kendall blockade=3 pieces=5 protect=run backward=1 reach26=exact throw_on_26=0]\n[first light]\n";
    is_deeply((parse_record($reorder))[1], { line => 1, error => 'variant' }, 'fields out of order');
    my $missing = "[variant kendall pieces=5 blockade=3 protect=run backward=1 reach26=exact]\n[first light]\n";
    is_deeply((parse_record($missing))[1], { line => 1, error => 'variant' }, 'a field missing');
    my $value = "[variant kendall pieces=8 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0]\n[first light]\n";
    is_deeply((parse_record($value))[1], { line => 1, error => 'variant' }, 'a field out of range');
    is_deeply((parse_record("$VARIANT{kendall}\n"))[1], { line => 2, error => 'first' }, 'no first');
    is_deeply((parse_record("$VARIANT{kendall}\n[first light]"))[1], { line => 0, error => 'no_newline' },
        'no final newline');
    is_deeply((parse_record("$VARIANT{kendall}\n[first light]\n1. l 1: 10-11x\n"))[1], { line => 3, error => 'move' },
        'a display mark on a record line is refused');
    is_deeply((parse_record("$VARIANT{kendall}\n[first light]\n[result light home]\n1. l 1: 10-11\n"))[1],
        { line => 4, error => 'after_result' }, 'nothing after the result');
};

# ---- the position string --------------------------------------------------------

subtest 'validate_position agrees with the engine' => sub {
    srand(16);
    my (@good, @bad);
    for (1 .. 500) {
        my $pieces = 1 + int(rand(7));
        my $bd = $E->new(pieces => $pieces);
        for my $side (0, 1) {
            my $want = int(rand($pieces + 1));
            while ($want) {
                my $h = 1 + int(rand(30));
                next if $bd->at($h);
                $bd->put($h, $side + 1);
                $want--;
            }
        }
        push @good, $bd->to_string;
    }
    push @bad, '', '........../.......... l 5', '........../........../........../.......... l 5',
        '........./........../.......... l 5', '........../.........../.......... l 5',
        '........../........../......... l 5', '/........../.......... l 5', '.........x/........../.......... l 5',
        '9........./........../.......... l 5', '.........L/........../.......... l 5',
        '........../........../.......... x 5', '........../........../.......... ld 5',
        '........../........../..........  l 5', '........../........../.......... l 0',
        '........../........../.......... l 8', '........../........../.......... l 55',
        '........../........../.......... l x', 'llllll..../........../.......... l 5',
        'dd......../........../.......... d 1', '........../........../..........',
        '........../........../.......... l', '........../........../.......... l ',
        '........../........../.......... l 5 0', join('/', ('.' x 10) x 3) . ' l 5' . (' ' x 12);
    while (@bad < 60) {
        my $s = $good[ @bad % @good ];
        my $i = int(rand(length $s));
        substr($s, $i, 1) = (qw(x / L 9 :), ' ')[ int(rand(6)) ];
        push @bad, $s;
    }
    my (@differ, %codes);
    for my $s (@good, @bad) {
        my (undef, $err) = $E->of_string($s);
        my $mine = validate_position($s);
        push @differ, "'$s' engine $err notation $mine" unless $mine == $err;
        $codes{$err}++ if $err;
    }
    is("@differ", '', scalar(@good) . ' good and ' . scalar(@bad) . ' bad strings, the same answer from both');
    is(scalar(grep { !$codes{$_} } 1 .. 9), 0, 'and all nine refusals are among the bad');
};

done_testing();
