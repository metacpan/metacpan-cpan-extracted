use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SthCapture;
use SthT qw(near_home);
use File::Temp ();

use Game::Sternhalma;
use Game::Sternhalma::Bot;
use Game::Sternhalma::Engine ();
use Game::Sternhalma::Notation qw(name_of hole_of);
use Game::Sternhalma::Terminal;
my $T = 'Game::Sternhalma::Terminal';
my $E = 'Game::Sternhalma::Engine';

# THE TERMINAL, PLAYED THROUGH A PIPE. Lines go in on one handle and the
# drawing comes out on another, which is all `sternhalma --no-pick` is.
# Nothing here needs a terminal, a shell or Term::ReadKey.

sub sitting {
    my ($lines, %with) = @_;
    my $typed = join '', map { "$_\n" } @$lines;
    my $written = '';
    open my $in, '<', \$typed or die "in: $!";
    my $out = SthCapture->handle(\$written);
    my $terminal = $T->new(
        in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0, pause => 0,
        bots => [], %with,
    );
    my $status = $terminal->start;
    close $out;
    return ($written, $terminal, $status);
}

sub plain_terminal { $T->new(interactive => 0, colour => 0, unicode => 0, picking => 0, out => SthCapture->handle(\my $sink), @_) }

# seat 0 a step from home: m6 to n1 takes it in; seat 1 likewise, e5 to d1
sub near { Game::Sternhalma->new(position => (near_home(2, 0))[0]->to_string) }

subtest 'the set-up, drawn' => sub {
    my $t = plain_terminal();
    my @lines = @{ $t->board_lines };
    is(scalar(@lines), 17, 'seventeen rows');
    is($lines[0], (' ' x 24) . 'a  R ', 'the top tip: its letter, then its one hole');
    is($lines[4], 'e  ' . join('   ', ('.') x 13) . ' ', 'the widest row: thirteen holes, four columns apart');
    is($lines[16], (' ' x 24) . 'q  B ', 'and the bottom tip, Blue');
    like($lines[2], qr/^ {20}c  R   R   R +> R Red    you     120$/, 'Red, beside the board: to play, at the keys, 120 to go');
    like($lines[3], qr/  B Blue   level 3 120$/, 'and Blue, the program at level 3');
    my ($widest) = sort { $b <=> $a } map { length } @lines;
    cmp_ok($widest, '<=', 80, "the whole drawing fits eighty columns: $widest");
};

# EVERY HOLE IS IN ITS COLUMN, and the column is the engine's geometry, not
# the drawing's own idea of it: a hole's column moves two a step east, and
# one for each row down to the south-east. Read back a character at a time.
subtest 'every hole is drawn where the engine puts it' => sub {
    my $game = Game::Sternhalma->new(seats => 6);
    my $t = plain_terminal(game => $game, bots => []);
    my @lines = @{ $t->board_lines };
    my $wrong = 0;
    for my $h (0 .. 120) {
        my $row = $E->row_of($h);
        my $at = $game->at($h);
        my $want = defined $at ? $Game::Sternhalma::Terminal::LETTER{ $t->colour_of($at) } : '.';
        my $got = substr $lines[$row], $t->column($h), 1;
        $wrong++ unless $got eq $want;
        my ($x, $y) = $E->xy($h);
        $wrong++ unless $t->column($h) == 2 + 2 * (2 * $x + $y + 12) + 1;
    }
    is($wrong, 0, 'all 121 holes: the piece or the dot that is there, in the column of its place');
    my @counts = map { my $l = substr $_, 0, 52; scalar(() = $l =~ /[RYGBPO.]/g) } @lines;
    is("@counts", '1 2 3 4 13 12 11 10 9 10 11 12 13 4 3 2 1', 'and the rows are the star\'s');
    my $centre = hole_of('i5');
    is(substr($lines[8], $t->column($centre), 1), '.', 'i5 is the middle of row i');
    is($t->column($centre), $t->column(hole_of('a1')), 'straight under the top tip');
};

# A PIECE IS A LETTER as well as a colour (D6): six seats told apart with no
# colour at all, and a different letter for every seat.
subtest 'every seat its own letter, with colour and without' => sub {
    my %letter = %Game::Sternhalma::Terminal::LETTER;
    is(scalar(keys %letter), 6, 'six colours');
    my %seen;
    $seen{$_}++ for values %letter;
    is(scalar(keys %seen), 6, 'six different letters');
    my $game = Game::Sternhalma->new(seats => 6);
    my $t = plain_terminal(game => $game, bots => []);
    my $drawn = join "\n", @{ $t->board_lines };
    for my $seat (0 .. 5) {
        my $l = $letter{ $t->colour_of($seat) };
        is(scalar(() = $drawn =~ /(?<= )\Q$l\E(?= )/g), 10 + 1, "seat $seat is ten ${l}s on the board, and one beside it");
    }
    is_deeply([ map { $t->colour_of($_) } 0 .. 5 ], [qw(red yellow green blue purple orange)], 'clockwise from the top');
    my $three = plain_terminal(seats => 3);
    is_deeply([ map { $three->colour_of($_) } 0 .. 2 ], [qw(red green purple)], 'three seats take every other point');
};

# COLOUR. The painted board is the lettered one with paint on it: strip the
# paint and the same characters are in the same columns.
subtest 'the painted board' => sub {
    my $sink = '';
    my $plain = plain_terminal(bots => []);
    my $painted = $T->new(interactive => 0, colour => 1, unicode => 0, picking => 0, bots => [], out => SthCapture->handle(\$sink));
    $_->command('c3-e7') for $plain, $painted;
    my @lettered = @{ $plain->board_lines };
    my @coloured = @{ $painted->board_lines };
    isnt($coloured[4], $lettered[4], 'colour changes the line');
    (my $stripped = join "\n", @coloured) =~ s/\e\[[0-9;]*m//g;
    is($stripped, join("\n", @lettered), 'and under the paint it is the same drawing');
    my %P = %Game::Sternhalma::Terminal::PIECE;
    like($coloured[2], qr/\e\[\Q$P{red}\EmR\e\[0m/, 'a red piece is its R on red');
    like($coloured[16], qr/\e\[\Q$P{blue}\EmB\e\[0m/, 'a blue one its B on blue');
    my ($g, $i) = ($Game::Sternhalma::Terminal::GROUND{last}, $Game::Sternhalma::Terminal::INK{last});
    like($coloured[4], qr/\e\[\Q$g;$i\Em:\e\[0m/, 'the frame of the last move is painted in its own ground and ink');
    my $dot = "$Game::Sternhalma::Terminal::GROUND{board};$Game::Sternhalma::Terminal::INK{red}";
    like($coloured[16], qr/^/, 'the home a seat is going to:');
    my $blue_home = "$Game::Sternhalma::Terminal::GROUND{board};$Game::Sternhalma::Terminal::INK{blue}";
    like($coloured[2], qr/\e\[\Q$blue_home\Em\.\e\[0m/, '  the hole Red left, in Blue\'s home, is a blue dot');
    my $hole = "$Game::Sternhalma::Terminal::GROUND{board};$Game::Sternhalma::Terminal::INK{hole}";
    like($coloured[8], qr/\e\[\Q$hole\Em\.\e\[0m/, '  and a hole in nobody\'s home a grey one');
    unlike($coloured[8], qr/\Q$dot\E/, '  never a seat\'s colour');

    my $wide = $T->new(interactive => 0, colour => 0, unicode => 1, picking => 0, bots => [], out => SthCapture->handle(\my $unread));
    my $row = join "\n", @{ $wide->board_lines };
    like($row, qr/\x{00B7}/, 'with unicode, a hole is a middle dot');
    like($row, qr/R/, 'and a piece still its letter');
};

# A MARK NEVER CHANGES A ROW. Every mark is brackets in the columns either
# side of a hole, which hold spaces when there is no mark.
subtest 'a mark never changes the width of a row' => sub {
    my $t = plain_terminal(bots => []);
    my @before = map { length } @{ $t->board_lines };
    $t->command('c3-e7');
    $t->focus(hole_of('e7'));
    for my $mode (qw(plain which)) {
        my @lines = @{ $t->board_lines($mode) };
        is_deeply([ map { length } @lines ], \@before, "$mode: every row as long as before");
    }
    $t->chosen(hole_of('o1'));
    $t->target(hole_of('m5'));
    my @lines = @{ $t->board_lines('where') };
    is_deeply([ map { length } @lines ], \@before, 'where, with a chain shown: the same');
    is(substr($lines[14], $t->column(hole_of('o1')) - 1, 3), '<B>', 'the piece picked up');
    is(substr($lines[12], $t->column(hole_of('m5')) - 1, 3), '[.]', 'the hole the cursor is on');
    my $kinds = join '', map { /([\[<({:])[.A-Z][\]>)}:]/g } @lines;
    like($kinds, qr/\(/, 'and the holes it can reach');
    for my $h (0 .. 120) {
        my $line = $lines[ $E->row_of($h) ];
        my $at = $t->column($h);
        my $cell = substr $line, $at - 1, 3;
        next if $cell =~ /\A [.A-Z] \z/;
        like($cell, qr/\A([\[<({:])[.A-Z]([\]>)}:])\z/, name_of($h) . " is framed: $cell") or last;
    }
};

subtest 'a move typed, and what the board says of it' => sub {
    my ($said, $t) = sitting([ 'a1-i5', 'c3-e7' ]);
    like($said, qr/^red> a1-i5$/m, 'the line typed is written back, since a pipe echoes nothing');
    like($said, qr/^a1-i5: that piece cannot get there this turn\. help lists the commands\.$/m, 'a move that cannot be made is refused, with the reason');
    like($said, qr/^Red played c3:e7\.$/m, 'the move, written as the chain it is');
    is_deeply([ $t->game->moves ], ['c3:e7'], 'one move was played');
    is_deeply($t->last, { seat => 0, move => 'c3:e7', path => [ hole_of('c3'), hole_of('e7') ] }, 'what the terminal remembers of it');
    like($said, qr/^Move 2\. Blue to play, B\.$/m, 'and it is Blue to play');
    like($said, qr/^ {20}c  R   R  :\.: .*Red    you     118$/m, 'the last move framed where it left, and Red 118 to go');
};

subtest 'each way a game ends, through the pipe' => sub {
    my ($said, $t) = sitting(['m6-n1'], game => near());
    like($said, qr/^Red is home, 1st\.$/m, 'the first seat home is told so');
    like($said, qr/^Every seat but one is home\.$/m, 'and with two seats that ends the game');
    like($said, qr/^1st Red, 2nd Blue\.$/m, 'the places');
    is($t->game->how, 'home', 'which the game calls home');
    like($said, qr/new or quit> \n\z/, 'and the prompt is the one for a game that is over');

    ($said, $t) = sitting(['resign']);
    like($said, qr/^Red resigns\.$/m, 'resigning: the seat to move');
    like($said, qr/^Nobody is left to race\.$/m, 'and the game is over');
    like($said, qr/^1st Blue, 2nd Red\.$/m, 'Blue first');

    ($said, $t) = sitting([ 'c3-e7', 'o1-m5' ], game => Game::Sternhalma->new(cap => 2));
    like($said, qr/^The game has reached its cap of 2 moves\.$/m, 'the cap, with its number');

    ($said, $t) = sitting([ 'm6-n1', 'c3-e7' ], game => near());
    like($said, qr/^The game is over\. new starts another\.$/m, 'a move typed after the end is told so');
};

subtest 'the program in the other seats' => sub {
    my ($said, $t) = sitting(['c3-e7'], bots => [1], level => 2);
    my $reply = ($t->game->moves)[1];
    ok(defined $reply, 'the program answered');
    like($said, qr/^Blue played \Q$reply\E\.$/m, 'and the answer is written out');
    my $alone = Game::Sternhalma->new;
    $alone->play('c3-e7');
    my $move = Game::Sternhalma::Bot->choose($alone, rung => 1, seed => 1);
    is($reply, $alone->board->move_text($move->{from}, $move->{to}), 'it is the move rung 1 chooses: level 2');
    is($t->rung, 1, 'which is the rung the terminal reports');

    ($said, $t) = sitting([], seats => 3, bots => [ 0, 1, 2 ], level => 1, game => Game::Sternhalma->new(seats => 3, cap => 30));
    ok($t->game->over, 'the program playing every seat plays on to the end');
    is($t->game->ply, 30, 'here the cap of thirty');
    cmp_ok(scalar(() = $said =~ /^ {24}a  /mg), '>=', 30, 'drawing the board after every move');

    ($said, $t) = sitting(['resign'], bots => [ 0, 1 ], game => Game::Sternhalma->new(cap => 2));
    like($said, qr/^There is nobody here to resign\.$/m, 'nobody here can resign for the program');
    is($t->game->how, 'cap', 'and the game ended as it was going to');
};

subtest 'the commands' => sub {
    my ($said, $t) = sitting(['moves']);
    like($said, qr/^  c1   c1:e5  c1:e7$/m, 'moves: a piece, and the holes it can end in') or diag $said;
    my @order = $said =~ /^  ([a-q][0-9]+) /mg;
    is("@order", 'c1 c2 c3 d1 d2 d3 d4', 'one line a piece, in the order they are drawn');

    ($said, $t) = sitting(['hint']);
    my $hint = Game::Sternhalma::Bot->choose(Game::Sternhalma->new, rung => 3, seed => 1);
    my $text = Game::Sternhalma->new->board->move_text($hint->{from}, $hint->{to});
    like($said, qr/^The program would play \Q$text\E\.$/m, "hint: the strongest rung's move, $text");
    is($t->game->ply, 0, 'and nothing is played');

    ($said, $t) = sitting([ 'level 4', 'level 9', 'level' ]);
    is($t->level, 4, 'level 4');
    like($said, qr/^Level 4: the program the strongest here\.$/m, 'said back');
    is(scalar(() = $said =~ /^A level is a number from 1 to 4\.$/mg), 2, 'a level that is not one is refused, twice');

    ($said, $t) = sitting([ 'c3-e7', 'new 3' ]);
    is($t->game->seats, 3, 'new 3: three seats');
    is($t->game->ply, 0, 'and a new game');
    is($t->last, undef, 'with no last move');
    like($said, qr/^A new game, for 3 seats\.$/m, 'said so');
    ($said, $t) = sitting([ 'new 5' ]);
    like($said, qr/^Five cannot play: one seat would have nobody opposite\.$/m, 'a seat count that is not one, with the reason');
    is($t->game->seats, 2, 'and nothing changed');

    ($said, $t) = sitting(['help']);
    like($said, qr/^  $_\b/m, "help lists $_") for qw(moves hint board level new save load undo redo resign rules quit pass arrows escape);

    ($said, $t) = sitting(['rules']);
    like($said, qr/A STEP/, 'rules: the step');
    like($said, qr/A HOP/, 'the hop');
    like($said, qr/or the game reaches 2000 moves/, "and the cap is the game's, 2000 for two seats");

    ($said, $t) = sitting([ 'quit', 'c3-e7' ]);
    is($t->game->ply, 0, 'quit stops: the line after it is not read');
    ($said, $t) = sitting([ '', '   ', 'board' ]);
    is(scalar(() = $said =~ /^ {24}a  /mg), 2, 'an empty line draws nothing, and board draws the board again');
};

subtest 'save and load' => sub {
    my $dir = File::Temp->newdir;
    my $file = "$dir/game.txt";
    my ($said, $t) = sitting([ 'c3-e7', 'o1-m5', "save $file" ]);
    like($said, qr/^Saved to \Q$file\E\.$/m, 'saved');
    my @moves = $t->game->moves;

    ($said, $t) = sitting([ "load $file" ]);
    like($said, qr/^Loaded \Q$file\E: 2 moves\.$/m, 'loaded');
    is_deeply([ $t->game->moves ], \@moves, 'the same two moves');

    ($said, $t) = sitting([ 'c3-e7', "load $dir/absent.txt" ]);
    like($said, qr/^Cannot read \Q$dir\E\/absent\.txt: /m, 'a file that is not there');
    is($t->game->ply, 1, 'leaves the game alone');

    open my $fh, '>', "$dir/bad.txt" or die $!;
    print {$fh} "this is not a game\n";
    close $fh;
    ($said, $t) = sitting([ 'c3-e7', "load $dir/bad.txt" ]);
    like($said, qr/bad\.txt is not a game of sternhalma: /, 'and a file that is not a game');
    is($t->game->ply, 1, 'leaves it alone too');
    ($said, $t) = sitting([ 'save', 'load' ]);
    like($said, qr/^save takes the name of a file\.$/m, 'save with no name');
    like($said, qr/^load takes the name of a file\.$/m, 'load with no name');

    ($said, $t) = sitting([ 'new 3', "save $file" ]);
    ($said, $t) = sitting([ "load $file" ], bots => [1]);
    is($t->game->seats, 3, 'a game for three loaded into a terminal set for two is for three');
};

# A WINDOW TOO NARROW SAYS SO, and says the number it needs.
subtest 'a window that is too narrow' => sub {
    my ($need) = sort { $b <=> $a } map { length } @{ plain_terminal()->board_lines };
    is($need, 78, q{the board and the seats beside it: 78 columns at the set-up for two, against the program});
    my $t = plain_terminal(width => $need - 1);
    my $screen = join "\n", @{ $t->screen('plain') };
    like($screen, qr/This window is 77 columns wide and the board needs 78\./, 'one column short: it says both numbers');
    unlike($screen, qr/^ +a  R/m, 'and draws no board');
    $t->width($need);
    like(join("\n", @{ $t->screen('plain') }), qr/^ +a  R/m, 'at exactly the width it needs, the board');
    my $colour = $T->new(interactive => 0, colour => 1, unicode => 0, picking => 0, width => $need, out => SthCapture->handle(\my $sink));
    like(join("\n", @{ $colour->screen('plain') }), qr/a.*R/, 'and the paint is not counted as width');
};

# EVERY MARK CAN BE SEEN. A mark is brackets first, which need no colour, and
# the colours are measured: the distance is the plain one between two colours
# in CIE Lab. The floors are Fanorona's:
#
#   60  a frame's ink from the ground it is written on
#   50  a piece's letter from its colour
#   35  a mark's ground from the board's, and from every other mark's;
#       a piece's colour from the board's
#   25  a dot from the board
subtest 'every colour, measured' => sub {
    my $rgb = sub {
        my ($n) = @_;
        return (8 + 10 * ($n - 232)) x 3 if $n >= 232;
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
    my $number = sub { defined $_[0] && $_[0] =~ /[34]8;5;(\d+)\z/ ? $1 : die "no colour in '" . ($_[0] // 'undef') . "'" };
    my %ground = map { $_ => $number->($Game::Sternhalma::Terminal::GROUND{$_}) } keys %Game::Sternhalma::Terminal::GROUND;
    my %ink = map { $_ => $number->($Game::Sternhalma::Terminal::INK{$_}) } keys %Game::Sternhalma::Terminal::INK;

    cmp_ok($apart->(220, 222), '<', 60, 'the measure calls gold on pale yellow too close, as a sibling found it was');
    cmp_ok($apart->(16, 231), '>', 99, 'and black from white as far as it goes');

    my @marks = qw(cursor held reach path last);
    is_deeply([ sort keys %Game::Sternhalma::Terminal::FRAME ], [ sort @marks ], 'five marks, and each has brackets');
    for my $mark (@marks) {
        my $far = $apart->($ink{$mark}, $ground{$mark});
        cmp_ok($far, '>=', 60, sprintf('the brackets of %s on its ground: %.0f apart', $mark, $far));
        $far = $apart->($ground{$mark}, $ground{board});
        cmp_ok($far, '>=', 35, sprintf('the ground of %s from the board: %.0f', $mark, $far));
    }
    for my $one (@marks) {
        for my $two (grep { $_ gt $one } @marks) {
            my $far = $apart->($ground{$one}, $ground{$two});
            cmp_ok($far, '>=', 35, sprintf('%s from %s: %.0f', $one, $two, $far));
        }
    }
    my %frames;
    $frames{ join '', @{ $Game::Sternhalma::Terminal::FRAME{$_} } }++ for @marks;
    is(scalar(keys %frames), 5, 'and five different brackets');

    for my $colour (@Game::Sternhalma::Terminal::COLOUR) {
        my ($bg, $fg) = $Game::Sternhalma::Terminal::PIECE{$colour} =~ /\A48;5;(\d+);1;38;5;(\d+)\z/
            or die "no piece colours for $colour";
        my $far = $apart->($fg, $bg);
        cmp_ok($far, '>=', 50, sprintf('a %s piece: its letter on its colour, %.0f', $colour, $far));
        $far = $apart->($bg, $ground{board});
        cmp_ok($far, '>=', 35, sprintf('  the piece from the board, %.0f', $far));
        $far = $apart->($ink{$colour}, $ground{board});
        cmp_ok($far, '>=', 25, sprintf('  a dot in its home from the board, %.0f', $far));
    }
    my $far = $apart->($ink{hole}, $ground{board});
    cmp_ok($far, '>=', 25, sprintf('a hole in nobody\'s home from the board: %.0f', $far));
};

subtest 'what new refuses' => sub {
    ok(!eval { $T->new(level => 5, interactive => 0); 1 }, 'a level that is not one');
    like($@, qr/level is 1 to 4/, 'with the reason');
    ok(!eval { $T->new(seats => 5, interactive => 0); 1 }, 'a seat count that is not one');
    like($@, qr/five cannot play/, 'with the reason');
    ok(!eval { $T->new(seats => 4, pieces => 15, interactive => 0); 1 }, 'fifteen pieces at four seats');
    ok(!eval { $T->new(bots => [2], interactive => 0); 1 }, 'a bot in a seat the game does not have');
    like($@, qr/there is no seat 2 in a game of 2/, 'with the reason');
    is_deeply($T->new(interactive => 0, bots => [ 1, 1, 0 ])->bots, [ 0, 1 ], 'a seat named twice is one seat');
    is_deeply($T->new(interactive => 0, seats => 4)->bots, [ 1, 2, 3 ], 'by default the program plays every seat but 0');
};

# TYPED PLAY ON A TERMINAL SCROLLS: nothing in it moves the cursor.
subtest 'typed play never clears what was said' => sub {
    my ($said, $t) = sitting([ 'c3-e7', 'level 2', 'new', 'c3-e7', 'resign' ], interactive => 1, width => 100);
    unlike($said, qr/\e/, 'no escape of any kind, on a terminal with the keys turned off');
    like($said, qr/^red> Red played c3:e7/m, 'and the line typed is not written a second time');
    like($said, qr/A new game, for 2 seats\.$/m, 'what a command said is still there');
    like($said, qr/^blue> Blue resigns\.$/m, q{to the end});
};

subtest 'it writes where it was told to, and nowhere else' => sub {
    open my $keep_out, '>&', \*STDOUT or die $!;
    open my $keep_err, '>&', \*STDERR or die $!;
    my $dir = File::Temp->newdir;
    open STDOUT, '>', "$dir/out" or die $!;
    open STDERR, '>', "$dir/err" or die $!;
    my ($said) = sitting([ 'c3-e7', 'moves', 'nonsense', 'hint', 'quit' ]);
    close STDOUT;
    close STDERR;
    open STDOUT, '>&', $keep_out or die $!;
    open STDERR, '>&', $keep_err or die $!;
    cmp_ok(length $said, '>', 500, 'the sitting said plenty, on its own handle');
    is(-s "$dir/out", 0, 'and nothing on STDOUT');
    is(-s "$dir/err", 0, 'and nothing on STDERR');
};

done_testing();
