use strict;
use warnings;
use Test::More;

use Game::Senet;

# EVERY REFUSAL, plan_game_senet/06. A move is played if and only if the
# generator offers it; the reasons only name why one that was not offered was
# refused, and a refusal changes nothing.

sub state_of {
    my ($g) = @_;
    my $turn = $g->turn;
    return join '|', $g->key, join('', @{ $g->sticks // [] }), $g->throws, $g->ply,
        $turn ? join(',', map { $_ // '-' } @{$turn}{qw(side segment bound extra)}) : 'over';
}

sub refused {
    my ($g, $move, $code, $what) = @_;
    my $before = state_of($g);
    ok(!$g->play($move), "refused: $what");
    is($g->error && $g->error->code, $code, "  as $code");
    is(state_of($g), $before, '  and nothing changed');
}

my $START = 'dldldldldl/........../.......... l 5';

subtest 'each refusal, from a move written for it' => sub {
    my $over = Game::Senet->new(script => [ 1 ], position => 'd........./........../.........l l 5');
    $over->play_or_die('30-off');
    ok(!$over->play('1-2'), 'refused: the game is over');
    is($over->error->code, 'game_over', '  as game_over');

    my $g = Game::Senet->new(script => [ 1 ]);
    refused($g, '10_11', 'bad_move', 'not a move at all');
    refused($g, '11-12', 'no_piece', 'no piece on 11');
    refused($g, '1-2', 'not_your_piece', 'dark\'s piece');
    refused($g, '10-12', 'wrong_distance', 'two houses on a 1');

    my $nothrow = Game::Senet->new(script => [ 2 ]);
    $nothrow->play_or_die('10-12');
    refused($nothrow, '1-3', 'no_roll', 'a script whose throws have run out');

    my $bound = Game::Senet->new(script => [ 2, 3 ], rules => 'skyruk', position => 'd........./........../.l.l...... l 5');
    $bound->play_or_die('24-26');
    refused($bound, '22-25', 'bound_piece', 'another piece while the throw is bound to 26');

    refused(Game::Senet->new(script => [ 1 ], position => '........../.........d/.l.l.d.... l 5'),
        '22-21', 'forward_first', 'a backward move while 22>23 exists');
    refused(Game::Senet->new(script => [ 1 ], position => 'd........./........../.....l.... l 5'),
        '26-25', 'no_back', 'a piece on 26 moving back');
    refused(Game::Senet->new(script => [ 3 ], position => 'd........./........../...l.l.... l 5'),
        '24-27', 'must_land_26', 'past 26 without stopping on it');
    refused(Game::Senet->new(script => [ 1 ], position => 'd........./........../.l.....l.. l 5'),
        '28-29', 'no_exit', '28 on a 1');
    refused(Game::Senet->new(script => [ 5 ], position => 'l...ddd..l/........../.......... l 5'),
        '1-6', 'blockade', 'past a row of three');
    refused(Game::Senet->new(script => [ 2 ]), '2-4', 'own_piece', 'onto light\'s own 4');
    refused(Game::Senet->new(script => [ 4 ], position => '........../l...d....l/.......... l 5'),
        '11-15', 'safe_house', 'onto dark on 15');
    refused(Game::Senet->new(script => [ 2 ], position => 'l.dd.....l/........../.......... l 5'),
        '1-3', 'protected', 'onto the end of dark\'s pair');
};

subtest 'the order, from moves wrong two or three ways' => sub {
    my $g = Game::Senet->new(script => [ 1 ]);
    refused($g, '1-3', 'not_your_piece', 'dark\'s piece, and two houses on a 1');
    refused($g, '11-13', 'no_piece', 'no piece, and the wrong distance');
    refused($g, '2-4', 'wrong_distance', 'the wrong distance, and onto light\'s own 4');
    my $bound = Game::Senet->new(script => [ 2, 3 ], rules => 'skyruk', position => 'd........./........../.l.l...... l 5');
    $bound->play_or_die('24-26');
    refused($bound, '22-30', 'bound_piece', 'another piece AND the wrong distance');
    refused(Game::Senet->new(script => [ 5 ], rules => 'skyruk', position => 'l.dd.dd..l/........../.......... l 5'),
        '1-6', 'blockade', 'past a pair under skyruk AND onto the end of another');
    refused(Game::Senet->new(script => [ 4 ], position => '........../l...dd...l/.......... l 5'),
        '11-15', 'safe_house', 'onto a safe house that is also protected: safe is asked first');
};

subtest 'a move made for another throw' => sub {
    my $one = Game::Senet->new(script => [ 1 ], rules => 'skyruk', position => 'd........./........../......l... l 5');
    my $two = Game::Senet->new(script => [ 2 ], rules => 'skyruk', position => 'd........./........../......l... l 5');
    my ($m1) = $one->legal;
    my ($m2) = $two->legal;
    is($m1->trace, '27>15', 'the water on a 1 is 27-15');
    is($m2->trace, '27>15', 'and on a 2 the same houses');
    ok(!$two->play($m1), 'the move made for the 1 is refused on the 2');
    ok($two->play($m2), 'and the 2\'s own is played');
};

for my $set (qw(kendall skyruk)) {
    subtest "every from and to, from forty positions, $set" => sub {
        srand($set eq 'kendall' ? 20 : 2020);
        my ($positions, $tried, $played, @bad) = (0, 0, 0);
        while ($positions < 40) {
            my @board = ('.') x 30;
            for my $side ('l', 'd') {
                my $want = 1 + int(rand(5));
                while ($want) {
                    my $h = int(rand(30));
                    next if $board[$h] ne '.';
                    $board[$h] = $side;
                    $want--;
                }
            }
            my $flat = join '', @board;
            my $pos = join('/', substr($flat, 0, 10), substr($flat, 10, 10), substr($flat, 20, 10)) . ' ' . (rand() < 0.5 ? 'l' : 'd') . ' 5';
            my $g = Game::Senet->new(script => [ 1 + int(rand(5)) ], rules => $set, position => $pos);
            next unless defined $g->roll;
            $positions++;
            my %legal = map { $_->from . '-' . ($_->off ? 'off' : $_->to) => 1 } $g->legal;
            my $before = state_of($g);
            for my $from (1 .. 30) {
                for my $to ((1 .. 30), 'off') {
                    next if $from eq $to;
                    my $wire = "$from-$to";
                    $tried++;
                    if ($g->play($wire)) {
                        $played++;
                        push @bad, "$pos $wire played, not legal" unless $legal{$wire};
                        $g->undo;
                        push @bad, "$pos $wire: undo did not restore" unless state_of($g) eq $before;
                    }
                    else {
                        my $code = $g->error->code;
                        push @bad, "$pos $wire legal, refused $code" if $legal{$wire};
                        push @bad, "$pos $wire refused with no reason of its own" if $code eq 'bad_move';
                        push @bad, "$pos $wire changed the game" unless state_of($g) eq $before;
                    }
                }
            }
        }
        is(scalar(@bad), 0, "$tried moves tried, $played played: played if and only if legal")
            or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
    };
}

done_testing();
