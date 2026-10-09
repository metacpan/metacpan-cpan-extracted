use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Game::Brandubh;
use Game::Brandubh::Terminal;
my $T = 'Game::Brandubh::Terminal';

# THE TERMINAL, PLAYED BY TYPING. Lines go in on one handle and everything it
# says comes out on another, so a whole sitting is a string in and a string
# out. Nothing here has a keyboard: the arrow keys are t/24's.

# one sitting: the lines typed, and what was written
sub sitting {
    my ($lines, %with) = @_;
    my $typed = join '', map { "$_\n" } @$lines;
    my $written = '';
    open my $in, '<', \$typed or die "in: $!";
    open my $out, '>', \$written or die "out: $!";
    my $terminal = $T->new(in => $in, out => $out, interactive => 0, colour => 0, picking => 0,
                           seed => 'T' x 32, %with);
    my $status = $terminal->start;
    close $out;
    return ($written, $terminal, $status);
}

subtest 'a new terminal' => sub {
    my ($said, $t, $status) = sitting(['quit']);
    is($status, 0, 'start returns 0, and returns: it does not exit');
    like($said, qr/Brandubh\. Type help for the commands\./, 'it says what it is');
    like($said, qr/^ 4 \| A \| A \| D \| K \| D \| A \| A \|$/m, 'and draws the set-up, the cross through rank 4');
    like($said, qr/^ 7 \| X \|   \|   \| A \|   \|   \| X \|$/m, 'with the corners marked X');
    like($said, qr/The attackers to move: you\./, 'whose move, by side and by who');
    like($said, qr/attackers> /, 'and a prompt that names the side to move');
    is($t->human, 'attackers', 'the person has the attackers unless told otherwise');
    is($t->level, 2, 'and the program plays at level 2');
    is($t->raw, 0, 'the keyboard was never taken over');
};

subtest 'the end of the input ends the sitting' => sub {
    my ($said, $t, $status) = sitting([]);
    is($status, 0, 'no lines at all: start still returns 0');
    like($said, qr/Bye\./, 'and it says goodbye');
};

subtest 'two people, typing moves' => sub {
    my ($said, $t) = sitting([ 'd1c1', 'd3 c3', 'D2-D1', 'quit' ], human => 'both');
    is("@{ $t->game->log }", 'd1c1 d3c3 d2d1', 'a move run together, one with a space, one in capitals with a hyphen');
    like($said, qr/The defenders to move: either of you\./, 'the turn passes between them');
    like($said, qr/1\. d1-c1  2\. d3-c3  3\. d2-d1/, 'and the moves are listed as they are shown');
    like($said, qr/^ 1 \| X \|   \| A \|'A'\|/m, 'the last move is marked on the board where it landed');
    like($said, qr/^ 2 \|   \|   \|   \|' '\|/m, 'and where it left');
};

subtest 'a refusal says what was wrong, and nothing moves' => sub {
    my ($said, $t) = sitting([ 'a4a7', 'd1d3', 'b2b3', 'd3c3', 'a4b5', 'd1d1', 'zz9', 'quit' ], human => 'both');
    is($t->game->ply, 0, 'seven lines, and not one move');
    like($said, qr/Only the king may stand on a corner\./, 'the corner');
    like($said, qr/Another piece is in the way\./, 'the blocked path');
    like($said, qr/There is no piece there\./, 'the empty square');
    like($said, qr/That piece is not yours\./, 'the other side\'s piece');
    like($said, qr/A piece moves in a straight line along a row or a column\./, 'the diagonal');
    like($said, qr/That piece did not move\./, 'the move to the same square');
    like($said, qr/I do not know 'zz9'\. A move is two squares, like d1d3\./, 'and a line that is not a move at all');
};

subtest 'the throne, when it is empty, is drawn and refused' => sub {
    my ($said, $t) = sitting([ 'a4d4', 'quit' ], human => 'both',
        game => Game::Brandubh->new(position => '7/7/7/a6/7/7/3k3 a'));
    like($said, qr/^ 4 \| A \|   \|   \| # \|/m, 'the empty throne is a #');
    like($said, qr/No piece may stop on the throne\./, 'and stopping on it is refused in words');
};

subtest 'moves, hint, help and rules' => sub {
    my ($said) = sitting([ 'moves', 'hint', 'help', 'rules', 'quit' ], human => 'both');
    like($said, qr/^  attacker d1  b1 c1 e1 f1$/m, 'moves: a piece, its square, where it can go');
    like($said, qr/40 moves\. x marks a capture, ! a move that wins\./, 'and the count');
    like($said, qr/The program would play [a-g][1-7]-[a-g][1-7]\./, 'hint names a move');
    like($said, qr/^  save FILE  +write the game to a file$/m, 'help lists the commands');
    like($said, qr/^  enter +pick the piece up, then put it down$/m, 'and the keys');
    like($said, qr/four round him on the throne, three\nwhen he stands beside it, and two/, 'rules: the king\'s three captures');
    like($said, qr/comes round for the third time/, 'and the repetition, as this game counts it');

    ($said) = sitting([ 'rules', 'quit' ], human => 'both', variant => { repeat => 2 });
    like($said, qr/comes round for the second time/, 'under another rule set the rules page says the other number');

    ($said) = sitting([ 'moves', 'quit' ], human => 'both',
        game => Game::Brandubh->new(position => '4a2/5ka/7/7/ad1da2/7/2a4 a'));
    like($said, qr/e7  .*e6xf6!/, 'a move that takes the king is marked x and !');
    like($said, qr/c1  .*c3xb3,d3/, 'and one that takes two lists both');
};

subtest 'a game to its end: the king home' => sub {
    my ($said, $t) = sitting([ 'a4a1', 'd1c1', 'quit' ], human => 'both',
        game => Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 d'));
    is($t->game->result->how, 'corner', 'won by a corner');
    like($said, qr/The king has reached a corner\. The defenders win\./, 'and it says so');
    like($said, qr/The game is over\. new starts another\./, 'a move after the end is turned away');
    like($said, qr/new, undo or quit> /, 'and the prompt offers what there is left to do');
};

subtest 'a game to its end: the king taken' => sub {
    my ($said, $t) = sitting([ 'e2e6', 'quit' ], human => 'attackers',
        game => Game::Brandubh->new(position => '7/5ka/7/7/7/4a2/7 a'));
    like($said, qr/The king is captured\. The attackers win\./, 'the capture');
    like($said, qr/You win\./, 'and whose it was');
    like($said, qr/King \. 0/, 'the king\'s place in the tray is empty');
};

subtest 'undo takes back your move and the reply to it' => sub {
    my ($said, $t) = sitting([ 'd1c1', 'undo', 'quit' ], human => 'attackers', level => 1);
    is($t->game->ply, 0, 'a move, the program\'s reply, and one undo: back at the start');
    like($said, qr/The defenders played /, 'the program did reply');
    like($said, qr/Taken back\./, 'and it says so');

    ($said, $t) = sitting([ 'd1c1', 'd3c3', 'undo', 'quit' ], human => 'both');
    is($t->game->ply, 1, 'between two people, undo takes back one move');

    ($said, $t) = sitting([ 'undo', 'quit' ], human => 'both');
    like($said, qr/There is nothing to take back\./, 'and none when none has been made');

    ($said, $t) = sitting([ 'resign', 'undo', 'quit' ], human => 'both');
    is($t->game->status, 'active', 'a resignation is taken back too');
};

subtest 'the program\'s move is told, and stays told' => sub {
    my ($said, $t) = sitting([ 'board', 'quit' ], human => 'defenders', level => 1);
    my @told = $said =~ /(The attackers played [a-g][1-7]-[a-g][1-7][^\n]*)/g;
    cmp_ok(scalar(@told), '>=', 2, 'the attackers, who are the program, moved first, and the line is on both drawings of the board');
    is($told[0], $told[1], 'the same line both times');
    is($t->game->ply, 1, 'one move made, and it was not the person\'s');
    like($said, qr/The defenders to move: you\./, 'and now it is the person\'s turn');
};

subtest 'level and side' => sub {
    my ($said, $t) = sitting([ 'level 3', 'level 9', 'level', 'side defenders', 'side kings', 'quit' ], human => 'both');
    is($t->level, 3, 'level 3 is set');
    like($said, qr/The program now plays at level 3\./, 'and said');
    is(() = $said =~ /A level is 1, 2 or 3\./g, 2, 'level 9 and no level are both turned away');
    like($said, qr/A side is attackers, defenders, both or none\./, 'and so is a side that is not one');
    is($t->human, 'defenders', 'the side that was one is taken');
    like($said, qr/The attackers played /, 'and the program, now the attackers, moves at once');

    ok(!eval { $T->new(human => 'kings'); 1 }, 'a terminal cannot be made with a side that is not one');
    ok(!eval { $T->new(level => 4); 1 }, 'nor with a level that is not');
};

subtest 'save and load' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/game.txt";
    my ($said, $t) = sitting([ 'd1c1', 'd3c3', "save $file", 'quit' ], human => 'both');
    like($said, qr/Saved to \Q$file\E\./, 'saved');
    ok(-s $file, 'and the file is there');

    open my $fh, '<', $file or die;
    my $text = do { local $/; <$fh> };
    close $fh;
    is($text, "variant brandubh\nmoves d1c1 d3c3\n", 'holding the rule set and the two moves');

    ($said, $t) = sitting([ "load $file", 'c1d1', 'quit' ], human => 'both');
    like($said, qr/Loaded \Q$file\E: 2 moves\./, 'loaded into another sitting');
    is("@{ $t->game->log }", 'd1c1 d3c3 c1d1', 'and carried on from');

    ($said) = sitting([ "load $dir/nothing.txt", 'save', 'load', "save $dir/no/such/dir/x", 'quit' ], human => 'both');
    like($said, qr/Cannot read \Q$dir\E\/nothing\.txt: /, 'a file that is not there');
    like($said, qr/save needs a file name\./, 'save with no name');
    like($said, qr/load needs a file name\./, 'load with no name');
    like($said, qr/Cannot write /, 'and a place that cannot be written');

    open my $bad, '>', "$dir/bad.txt" or die;
    print {$bad} "hello\n";
    close $bad;
    ($said) = sitting([ "load $dir/bad.txt", 'quit' ], human => 'both');
    like($said, qr/bad\.txt is not a saved game\./, 'a file that is not a game');

    open $bad, '>', "$dir/wrong.txt" or die;
    print {$bad} "variant brandubh\nmoves d1c1 a4a7\n";
    close $bad;
    ($said, $t) = sitting([ "load $dir/wrong.txt", 'quit' ], human => 'both');
    like($said, qr/wrong\.txt is not a game I can play: move 2 is refused/, 'and one with a move in it that cannot be played');
    is($t->game->ply, 0, 'which leaves the game in hand alone');
};

subtest 'draw and resign' => sub {
    my ($said, $t) = sitting([ 'draw', 'quit' ], human => 'both');
    is($t->game->result->how, 'agreed', 'two people: a draw offered is a draw agreed');
    like($said, qr/A draw, by agreement\./, 'and said');

    ($said, $t) = sitting([ 'resign', 'quit' ], human => 'defenders', level => 1);
    is($t->game->result->how, 'resign', 'a resignation');
    is($t->game->result->winner, 'attackers', 'gives the game to the other side');
    like($said, qr/The defenders resign\. The attackers win\./, 'in words');
    like($said, qr/The program wins\./, 'and says whose that is');

    ($said, $t) = sitting([ 'resign', 'resign', 'draw', 'quit' ], human => 'both');
    is(() = $said =~ /The game is over\./g, 2, 'neither can be done twice');

    # AGAINST THE PROGRAM A DRAW IS ASKED FOR, NOT TAKEN. It agrees unless it
    # thinks it is winning, and it is asked in one position where it has won
    # and one where it has lost.
    ($said, $t) = sitting([ 'draw', 'quit' ], human => 'attackers', level => 1,
        game => Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 a'));
    like($said, qr/The program declines the draw\./, 'the program, a move from winning, declines');
    is($t->game->status, 'active', 'and the game goes on');

    ($said, $t) = sitting([ 'draw', 'quit' ], human => 'defenders', level => 1,
        game => Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 d'));
    is($t->game->result->how, 'agreed', 'the program, a move from losing, agrees');
};

subtest 'new, and the repetition warning' => sub {
    my ($said, $t) = sitting([ qw(a4a3 c4c3 a3a4 c3c4), 'quit' ], human => 'both');
    like($said, qr/This position has now stood 2 times\. At 3 the game is drawn\./, 'the second time a position stands, it is said');
    unlike($said, qr/stood 1 time/, 'and not the first');

    ($said, $t) = sitting([ qw(a4a3 c4c3 a3a4 c3c4 a4a3 c4c3 a3a4 c3c4), 'new', 'd1c1', 'quit' ], human => 'both');
    like($said, qr/The same position has come round once too often\. The game is drawn\./, 'the third time, the game is drawn');
    like($said, qr/A new game\./, 'new starts another');
    is("@{ $t->game->log }", 'd1c1', 'from the set-up');
};

subtest 'watching the program play itself' => sub {
    my ($said, $t) = sitting([], human => 'none', level => 1, pause => 0, variant => { ply_cap => 60 });
    is($t->game->status, 'finished', 'with nothing typed, the game is played to its end');
    cmp_ok($t->game->ply, '>', 3, 'in ' . $t->game->ply . ' moves');
    my @told = $said =~ /^The (?:attackers|defenders) played /mg;
    is(scalar(@told), $t->game->ply, 'and every one of them was told');
};

subtest 'colour, asked for, is there; not asked for, is not' => sub {
    my ($plain) = sitting(['quit'], human => 'both');
    unlike($plain, qr/\e/, 'no escape sequence without colour');
    unlike($plain, qr/[^\x00-\x7F]/, 'and nothing outside ASCII');

    my ($painted) = sitting(['quit'], human => 'both', colour => 1, unicode => 1);
    like($painted, qr/\e\[48;5;\d+;[0-9;]+m/, 'with colour, squares have a ground and an ink');
    like($painted, qr/\xE2\x96\xB2/, 'and the attacker is a triangle');
    my %grounds = map { $_ => 1 } $painted =~ /\e\[(48;5;\d+)[;m]/g;
    cmp_ok(scalar(keys %grounds), '>=', 4, 'in at least four grounds: two for the squares, the throne, the corners');

    my ($toggled) = sitting([ 'colour', 'board', 'quit' ], human => 'both');
    like($toggled, qr/\e\[/, 'the colour command turns it on');
};

subtest 'it writes where it is told and nowhere else' => sub {
    my ($out, $err) = ('', '');
    open my $keep_out, '>&', \*STDOUT or die;
    open my $keep_err, '>&', \*STDERR or die;
    close STDOUT; close STDERR;
    open STDOUT, '>', \$out or die;
    open STDERR, '>', \$err or die;
    my ($said) = sitting([ 'd1c1', 'moves', 'help', 'zz', 'quit' ], human => 'both');
    close STDOUT; close STDERR;
    open STDOUT, '>&', $keep_out or die;
    open STDERR, '>&', $keep_err or die;
    cmp_ok(length $said, '>', 500, 'the sitting said plenty, on its own handle');
    is($out, '', 'and nothing on STDOUT');
    is($err, '', 'and nothing on STDERR');
};

# THE KING CAN BE SEEN ON EVERY SQUARE HE CAN STAND ON. He was gold, and the
# square a piece has just left or reached is painted pale yellow, so after his
# own move he vanished. The distance is the plain one between two colours in
# CIE Lab; 60 is far apart, and gold on the pale yellow scored 43.
subtest 'the king stands out from every square, and from the other pieces' => sub {
    my $rgb = sub {
        my ($n) = @_;
        return (8 + 10 * ($n - 232)) x 3 if $n >= 232;
        return ($n == 16 ? 0 : 255) x 3 if $n < 17 && ($n == 16 || $n == 15);
        die "colour $n is one of the terminal's own sixteen, which no two terminals agree on" if $n < 16;
        my @level = (0, 95, 135, 175, 215, 255);
        $n -= 16;
        return ($level[ int($n / 36) ], $level[ int($n / 6) % 6 ], $level[ $n % 6 ]);
    };
    my $lab = sub {
        my @c = map { my $v = $_ / 255; $v <= 0.04045 ? $v / 12.92 : (($v + 0.055) / 1.055) ** 2.4 } $rgb->($_[0]);
        my @xyz = (($c[0] * 0.4124 + $c[1] * 0.3576 + $c[2] * 0.1805) / 0.95047,
                    $c[0] * 0.2126 + $c[1] * 0.7152 + $c[2] * 0.0722,
                   ($c[0] * 0.0193 + $c[1] * 0.1192 + $c[2] * 0.9505) / 1.08883);
        my @f = map { $_ > 0.008856 ? $_ ** (1 / 3) : 7.787 * $_ + 16 / 116 } @xyz;
        return (116 * $f[1] - 16, 500 * ($f[0] - $f[1]), 200 * ($f[1] - $f[2]));
    };
    my $apart = sub {
        my @p = $lab->($_[0]);
        my @q = $lab->($_[1]);
        return sqrt(($p[0] - $q[0]) ** 2 + ($p[1] - $q[1]) ** 2 + ($p[2] - $q[2]) ** 2);
    };
    my $number = sub { $_[0] =~ /[34]8;5;(\d+)\z/ ? $1 : die "no colour in '$_[0]'" };

    cmp_ok($apart->(220, 222), '<', 60, 'the measure calls gold on pale yellow too close, which it was');

    my $king = $number->($Game::Brandubh::Terminal::INK{king});
    for my $ground (qw(light dark throne corner cursor from to reach trail)) {
        my $far = $apart->($king, $number->($Game::Brandubh::Terminal::GROUND{$ground}));
        cmp_ok($far, '>=', 60, sprintf('the king on a %s square: %.0f apart', $ground, $far));
    }
    for my $piece (qw(attacker defender)) {
        my $far = $apart->($king, $number->($Game::Brandubh::Terminal::INK{$piece}));
        cmp_ok($far, '>=', 60, sprintf('the king beside the %s: %.0f apart', $piece, $far));
    }
};

done_testing();
