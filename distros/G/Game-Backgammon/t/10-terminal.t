#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Backgammon;
use Game::Backgammon::Terminal;

# The terminal layer, driven through its handles rather than by a person.
# A UI that only a human can run is a UI that rots without anybody noticing,
# which is why `in` and `out` are attributes.

sub seed_of { Digest::SHA::sha256($_[0]) }

sub capture {
    my (%o) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $in;
    if (defined $o{input}) { open $in, '<', \$o{input} or die $! }
    my $ui = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of($o{seed} // 'term')),
        out => $fh, ($in ? (in => $in) : ()),
        mode => $o{mode} // 'watch', level => $o{level} // 2,
        ($o{seat} ? (seat => $o{seat}) : ()),
    );
    my $result = $ui->run;
    close $fh;
    return ($out, $result, $ui);
}

subtest 'the board renders' => sub {
    plan tests => 3;
    # the opening position drawn from white's side, written out by hand: the
    # two halves between their borders, the bar down the middle, the tray on
    # the right, and the pip counts beside the side they belong to
    my @expect = split /\n/, <<'BOARD';
 +13-14-15-16-17-18-+---+19-20-21-22-23-24-+---+
 | O           X    |   | X              O |   |  Black 167 pips
 | O           X    |   | X              O |   |
 | O           X    |   | X                |   |
 | O                |   | X                |   |
 | O                |   | X                |   |
 |                  |BAR|                  |OFF|
 | X                |   | O                |   |
 | X                |   | O                |   |
 | X           O    |   | O                |   |
 | X           O    |   | O              X |   |
 | X           O    |   | O              X |   |  White 167 pips
 +12-11-10--9--8--7-+---+-6--5--4--3--2--1-+---+
  the points are numbered from white
BOARD

    my $ui = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of('render')),
        ascii => 1, colour => 0, interactive => 0);

    is_deeply($ui->board_lines('white'), \@expect, 'the board is drawn as designed');

    # the same position from black's side: the shape of the opening is
    # symmetric, so it is the same picture with the colours the other way
    # round, each side's own home in the bottom right of its own board
    my @black = split /\n/, <<'BOARD';
 +13-14-15-16-17-18-+---+19-20-21-22-23-24-+---+
 | X           O    |   | O              X |   |  White 167 pips
 | X           O    |   | O              X |   |
 | X           O    |   | O                |   |
 | X                |   | O                |   |
 | X                |   | O                |   |
 |                  |BAR|                  |OFF|
 | O                |   | X                |   |
 | O                |   | X                |   |
 | O           X    |   | X                |   |
 | O           X    |   | X              O |   |
 | O           X    |   | X              O |   |  Black 167 pips
 +12-11-10--9--8--7-+---+-6--5--4--3--2--1-+---+
  the points are numbered from black
BOARD
    is_deeply($ui->board_lines('black'), \@black,
        'and the other side gets its own numbering');

    my $wide = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of('render')),
        colour => 0, interactive => 0);
    like($wide->render('white'), qr/[^\x00-\x7f]/,
        'without ascii the checkers are the round ones');
};

subtest 'the bar, the tray, and a point too tall to draw' => sub {
    plan tests => 5;
    my $game = Game::Backgammon->new(seed => seed_of('stacks'));
    my $board = $game->board;
    $board->set_point('white', $_, 0) for 1 .. 24;
    $board->set_point('black', $_, 0) for 1 .. 24;
    $board->set_point('white', 6, 8);          # taller than the board is
    $board->set_point('black', 13, 4);
    $board->to_bar('white', 3);
    $board->to_bar('black', 1);
    $board->to_off('white', 4);
    $board->to_off('black', 10);

    my $ui = Game::Backgammon::Terminal->new(
        game => $game, ascii => 1, colour => 0, interactive => 0);
    my $lines = $ui->board_lines('white');
    # every cell is three columns wide, so a column of the picture can be
    # read straight out of the line: the bar, the first point of the right
    # hand quadrant, and the tray
    my $bar   = sub { substr $lines->[ $_[0] ], 21, 3 };
    my $six   = sub { substr $lines->[ $_[0] ], 25, 3 };
    my $tray  = sub { substr $lines->[ $_[0] ], 44, 3 };

    is(scalar(grep { $six->($_) eq ' O ' } 8 .. 11), 4,
        'a point of eight draws four checkers');
    is($six->(7), ' 8 ', 'and says how many there are in the last place');

    # your own checkers on the bar sit in the top of the middle column,
    # because that is the end of the board you come back in at
    is(scalar(grep { $bar->($_) eq ' O ' } 1 .. 5), 3,
        'three on the bar are drawn in your half of it');
    is(scalar(grep { $bar->($_) eq ' X ' } 7 .. 11), 1,
        "and the opponent's one in theirs");

    # the tray is beside the home board it fills from: yours bottom right,
    # and ten borne off is past what the column can draw
    is(join('', map { $tray->($_) } 1 .. 5, 7 .. 11),
        ' X  X  X  X 10 ' . '    O  O  O  O ',
        'the trays fill from their own ends, and ten is a number, not a stack');
};

subtest 'a watched game plays itself to the end' => sub {
    plan tests => 3;
    my ($out, $result) = capture(seed => 'watched', mode => 'watch', level => 2);
    ok($result, 'the game finished');
    like($out, qr/wins a (?:single|gammon|backgammon)/, 'and said so');
    like($out, qr/\bto play \d-\d/, 'having announced the dice each turn');
};

subtest 'a person picks a turn by number' => sub {
    plan tests => 3;
    # answer '1' forever: the first legal turn, every time
    my ($out, $result) = capture(seed => 'played', mode => 'bot', seat => 'white',
                                 level => 2, input => ("1\n" x 4000));
    ok($result, 'a game against the bot finishes');
    like($out, qr/^\s+1\) /m, 'the turns were offered as a numbered list');
    unlike($out, qr/pick a number/, 'and a valid answer was never argued with');
};

subtest 'the legal turns are offered across the screen' => sub {
    plan tests => 4;
    # doubles from the bar can offer thirty turns, and thirty lines push the
    # board they belong to off the top of the screen
    my $ui = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of('offer')),
        ascii => 1, colour => 0, interactive => 0);
    my $turns = $ui->game->legal_turns;
    my $lines = $ui->offer_lines($turns);

    cmp_ok(scalar @$lines, '<', scalar @$turns, 'more turns than lines');
    ok(!grep({ length > 78 } @$lines), 'and no line wider than a terminal');
    like($lines->[0], qr/\A\s+1\) /, 'the first is numbered 1');
    is(scalar(() = join("\n", @$lines) =~ m/\d+\)/g), scalar @$turns,
        'every turn is offered exactly once');
};

subtest 'a bad answer is refused, not fatal' => sub {
    plan tests => 2;
    my ($out, $result) = capture(seed => 'bad-input', mode => 'bot', seat => 'white',
                                 level => 2, input => "nonsense\n0\n999\n" . ("1\n" x 4000));
    like($out, qr/pick a number from the list/, 'a bad answer is answered');
    ok($result, 'and the game still finishes');
};

subtest 'q stops the game without finishing it' => sub {
    plan tests => 2;
    my ($out, $result) = capture(seed => 'quit', mode => 'bot', seat => 'white',
                                 level => 2, input => "q\n");
    is($result, undef, 'there is no result');
    like($out, qr/stopped/, 'and it says it stopped');
};

subtest 'running out of input gives up cleanly' => sub {
    plan tests => 1;
    # end of input is not a crash: it is somebody closing the terminal
    my ($out, $result) = capture(seed => 'eof', mode => 'bot', seat => 'white',
                                 level => 2, input => '');
    like($out, qr/stopped/, 'end of input stops the game rather than dying');
};

done_testing();
