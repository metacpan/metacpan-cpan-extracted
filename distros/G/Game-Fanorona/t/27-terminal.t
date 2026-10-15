use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use FnCapture;
use File::Temp ();

use Game::Fanorona;
use Game::Fanorona::Bot;
use Game::Fanorona::Engine;
use Game::Fanorona::Notation qw(square_of);
use Game::Fanorona::Terminal;
my $T = 'Game::Fanorona::Terminal';

# THE TERMINAL, PLAYED THROUGH A PIPE. Lines go in on one handle and the
# drawing comes out on another, which is all `fanorona --no-pick` is. Nothing
# here needs a terminal, a shell or Term::ReadKey.

sub sitting {
    my ($lines, %with) = @_;
    my $typed = join '', map { "$_\n" } @$lines;
    my $written = '';
    open my $in, '<', \$typed or die "in: $!";
    my $out = FnCapture->handle(\$written);
    my $terminal = $T->new(
        in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0, pause => 0,
        human => 'both', %with,
    );
    my $status = $terminal->start;
    close $out;
    return ($written, $terminal, $status);
}

sub board_of { { cols => 9, rows => 5, start => $_[0], @_[1 .. $#_] } }

# the last board drawn in what was written, as its rows
sub last_board {
    my ($written) = @_;
    my @rows = $written =~ /^([1-5] [^\n]*)$/mg;
    my ($top) = grep { $rows[$_] =~ /^5 / } reverse 0 .. $#rows;
    return @rows[ $top .. $#rows ];
}

subtest 'the set-up, drawn' => sub {
    my $t = $T->new(interactive => 0, colour => 0, unicode => 0, picking => 0);
    my @want = (
        '5  X---X---X---X---X---X---X---X---X    Black X  22 left  taken 0',
        '   | \\ | / | \\ | / | \\ | / | \\ | / |',
        '4  X---X---X---X---X---X---X---X---X',
        '   | / | \\ | / | \\ | / | \\ | / | \\ |',
        '3  X---O---X---O---+---X---O---X---O',
        '   | \\ | / | \\ | / | \\ | / | \\ | / |',
        '2  O---O---O---O---O---O---O---O---O',
        '   | / | \\ | / | \\ | / | \\ | / | \\ |',
        '1  O---O---O---O---O---O---O---O---O    White O  22 left  taken 0',
        '   a   b   c   d   e   f   g   h   i',
    );
    is(join("\n", @{ $t->board_lines }), join("\n", @want), 'nine by five, as stored');

    my $small = $T->new(interactive => 0, colour => 0, unicode => 0, picking => 0, variant => 'telo');
    is(join("\n", @{ $small->board_lines }), join("\n",
        '3  X---X---X    Black X   4 left  taken 0',
        '   | \\ | / |',
        '2  O---+---X',
        '   | / | \\ |',
        '1  O---O---O    White O   4 left  taken 0',
        '   a   b   c',
    ), 'and three by three');
};

# THE DIAGONALS ARE THE ENGINE'S, not the drawing's own idea of them. A cell of
# four points has one diagonal, and it runs between the two that are strong.
# The drawing is read back a character at a time and each one is asked of the
# engine: 32 cells on the big board.
subtest 'a diagonal is drawn where the engine has one, and nowhere else' => sub {
    my $E = 'Game::Fanorona::Engine';
    my $t = $T->new(interactive => 0, colour => 0, unicode => 0, picking => 0);
    my @lines = @{ $t->board_lines };
    my ($cells, $wrong) = (0, 0);
    for my $lower (0 .. 3) {
        my $row = $lines[ 2 * (4 - $lower) - 1 ];
        for my $file (0 .. 7) {
            my $drawn = substr $row, 3 + 4 * $file + 2, 1;
            my $strong = $E->is_strong(square_of(chr(97 + $file) . ($lower + 1)));
            my $rising = $strong ? 1 : 0;
            $cells++;
            $wrong++ unless $drawn eq ($rising ? '/' : '\\');
            $wrong++ unless $E->is_strong(square_of(chr(98 + $file) . ($lower + 2))) == $strong;
        }
    }
    is($cells, 32, 'thirty-two cells read');
    is($wrong, 0, 'each has the diagonal that joins its two strong corners');
    is(substr($lines[7], 5, 1), '/', 'and a1, a strong point, has one rising from it');
    is(substr($lines[8], 3, 1), 'O', 'the column that was read is the one the stone at a1 is drawn in');
};

subtest 'a move typed, and what the board says of it' => sub {
    my ($said, $t) = sitting([ 'd3-e3', 'd3-e3A' ]);
    like($said, qr/^white> d3-e3$/m, 'the line typed is written back, since a pipe echoes nothing');
    like($said, qr/d3-e3: that step can take two ways: say which, A or W\./, 'a step that takes two ways and names neither is refused with the reason');
    like($said, qr/^White played d3-e3A, taking 1 stone\.$/m, 'the move, and what it took');
    is_deeply([ $t->game->moves ], ['d3-e3A'], 'one move was played');
    my @board = last_board($said);
    is($board[2], '3  X---O---X--:+:-:O:-:*:--O---X---O', 'the last move is framed: where it left, where it stands, and what it took');
    like($board[0], qr/Black X  21 left  taken 0$/, 'Black has a stone fewer');
    like($board[4], qr/White O  22 left  taken 1$/, 'and White has taken one');
    like($said, qr/^Move 2\. Black to play, X\.$/m, 'and it is Black to play');
    is_deeply($t->last, { side => 'white', move => 'd3-e3A', points => [qw(d3 e3)], taken => ['f3'] },
        'what the terminal remembers of it');
};

subtest 'each way a game ends, through the pipe' => sub {
    my ($said, $t) = sitting(['a3-b3A'], variant => board_of('9/9/w1b6/9/9 w'));
    like($said, qr/^Black has no stone left\. White wins\.$/m, 'the last stone');
    is($t->game->result->how, 'stones', 'which the game calls stones');
    like($said, qr/new or quit> \n\z/, 'and the prompt is the one for a game that is over');

    ($said, $t) = sitting(['b3-b2'], variant => board_of('9/9/bb7/b8/wbb6 b'));
    like($said, qr/^White has no move left, and so has lost\. Black wins\.$/m, 'a side that cannot move');
    is($t->game->result->how, 'no_moves', 'no_moves');

    my @round = ('a1-a2', 'i5-i4', 'a2-a1', 'i4-i5');
    ($said, $t) = sitting([ @round, @round ], variant => board_of('8b/9/9/9/w8 w'));
    like($said, qr/^The same position has come round once too often\. The game is drawn\.$/m, 'the third time');
    is($t->game->result->how, 'repetition', 'repetition');

    ($said, $t) = sitting([ 'a1-a2', 'i5-i4', 'a2-a3', 'i4-i3', 'a3-a4' ],
        variant => board_of('8b/9/9/9/w8 w', quiet_limit => 5, repeat => 0));
    like($said, qr/^Nothing has been taken for 5 moves\. The game is drawn\.$/m, 'the quiet limit, with its number');
    is($t->game->result->how, 'quiet', 'quiet');

    ($said, $t) = sitting([ 'a1-a2', 'i5-i4', 'a2-a3', 'i4-i3', 'a3-a4', 'i3-i2' ],
        variant => board_of('8b/9/9/9/w8 w', quiet_limit => 0, repeat => 0, ply_cap => 6));
    like($said, qr/^The game has run its full length with no end\. It is drawn\.$/m, 'the cap');
    is($t->game->result->how, 'ply_cap', 'ply_cap');

    ($said, $t) = sitting([ 'd2-e3A', 'resign' ]);
    like($said, qr/^Black resigns\. White wins\.$/m, 'resigning: the side to move, when both are played here');
    is($t->game->result->how, 'resign', 'resign');

    ($said, $t) = sitting([ 'draw', 'decline', 'draw', 'accept' ]);
    like($said, qr/^White offers a draw\. accept or decline answers it\.$/m, 'a draw offered across the table');
    like($said, qr/^Black declines the draw\.$/m, 'declined');
    like($said, qr/^A draw, by agreement\.$/m, 'and then agreed');
    is($t->game->result->how, 'agreement', 'agreement');

    ($said, $t) = sitting([ 'a3-b3A', 'a1-a2' ], variant => board_of('9/9/w1b6/9/9 w'));
    like($said, qr/^The game is over\. new starts another\.$/m, 'a move typed after the end is told so');
};

subtest 'the program on the other side' => sub {
    my ($said, $t) = sitting([ 'd2-e3A' ], human => 'white', level => 2);
    my $reply = ($t->game->moves)[1];
    ok(defined $reply, 'the program answered');
    like($said, qr/^Black played \Q$reply\E/m, 'and the answer is written out');
    is($t->game->ply, 2, 'two moves played');
    like($said, qr/^Move 3\. White to play, O\.$/m, 'and it is White again');
    my $alone = Game::Fanorona->new(script => ['d2-e3A']);
    is($reply, Game::Fanorona::Bot->choose($alone, level => 100), 'it is the move the bot chooses at the second level, 100 positions');
    is($t->budget, 100, 'which is the budget the terminal reports');

    ($said, $t) = sitting([ 'draw' ], human => 'white');
    like($said, qr/^The program declines the draw\.$/m, 'a draw offered to the program at the set-up is declined');
    ok(!$t->game->over, 'and the game goes on');
    is($t->game->draw_offered_by, undef, 'with no offer left standing');

    ($said, $t) = sitting([ 'draw' ], human => 'white', variant => board_of('9/9/w1b6/9/8w w'));
    like($said, qr/^The program accepts\.$/m, 'a stone behind, it accepts');
    like($said, qr/^A draw, by agreement\.$/m, 'and the game is drawn');

    ($said, $t) = sitting([], human => 'neither', variant => 'telo');
    ok($t->game->over, 'the program against itself plays three by three to the end');
    like($said, qr/has no stone left|has no move left|is drawn/, 'and says how it ended');
    cmp_ok(scalar(() = $said =~ /^3 /mg), '>=', $t->game->ply, 'drawing the board after every move');

    ($said, $t) = sitting([ 'resign', 'draw' ], human => 'neither', variant => board_of('8b/9/9/9/w8 w', ply_cap => 2));
    like($said, qr/^There is no game being played here to resign\.$/m, 'nobody here can resign for the program');
    like($said, qr/^There is no game being played here to draw\.$/m, 'or offer a draw for it');
    is($t->game->result->how, 'ply_cap', 'and the game ended as it was going to');
};

subtest 'the commands' => sub {
    my ($said, $t) = sitting(['moves']);
    like($said, qr/^  d3  d3-e3A takes 1   d3-e3W takes 1$/m, 'moves: a stone, and each step with what it takes');
    like($said, qr/^  f2  f2-e3A takes 2$/m, 'one line a stone');
    is(scalar(() = $said =~ /^  [a-i][1-5]  /mg), 4, 'four stones can move at the set-up');
    my @order = $said =~ /^  ([a-i][1-5])  /mg;
    is("@order", 'd3 d2 e2 f2', 'in the order they are drawn');

    ($said, $t) = sitting(['hint']);
    my $hint = Game::Fanorona::Bot->hint(Game::Fanorona->new)->{move};
    like($said, qr/^The program would play \Q$hint\E\.$/m, "hint: the strongest level's move, $hint");
    is($t->game->ply, 0, 'and nothing is played');

    ($said, $t) = sitting([ 'level 5', 'level 9', 'level' ]);
    is($t->level, 5, 'level 5');
    like($said, qr/^Level 5: the program the strongest here\.$/m, 'said back');
    is(scalar(() = $said =~ /^A level is a number from 1 to 5\.$/mg), 2, 'a level that is not one is refused, twice');

    ($said, $t) = sitting([ 'side black' ], human => 'white', level => 1);
    is($t->human, 'black', 'side black');
    is($t->game->ply, 1, 'and the program, now White, moved');
    ($said, $t) = sitting([ 'side purple' ]);
    like($said, qr/^A side is white, black, both or neither\.$/m, 'a side that is not one');
    is($t->human, 'both', 'changes nothing');

    ($said, $t) = sitting([ 'd2-e3A', 'new telo' ]);
    is($t->game->variant->name, 'telo', 'new telo: another board');
    is($t->game->ply, 0, 'and a new game');
    is($t->last, undef, 'with no last move');
    ($said, $t) = sitting([ 'new chess' ]);
    like($said, qr/^chess is not a board\. The boards are sivy, dimy, telo\.$/m, 'a board that is not one');

    ($said, $t) = sitting(['help']);
    like($said, qr/^  $_\b/m, "help lists $_") for qw(moves hint board level side new save load draw resign rules quit backspace escape);
    like($said, qr/^  undo\b/m, 'and offers undo to take a move back');

    ($said, $t) = sitting(['rules']);
    like($said, qr/TAKING BY APPROACH/, 'rules: approach');
    like($said, qr/TAKING BY WITHDRAWAL/, 'withdrawal');
    like($said, qr/when 60 moves running take nothing/, "and the quiet limit is the game's, 60");
    ($said, $t) = sitting(['rules'], variant => board_of('8b/9/9/9/w8 w', quiet_limit => 12));
    like($said, qr/when 12 moves running take nothing/, 'or 12 when the game was made with 12');

    ($said, $t) = sitting([ 'quit', 'd2-e3A' ]);
    is($t->game->ply, 0, 'quit stops: the line after it is not read');
    ($said, $t) = sitting([ '', '   ', 'board' ]);
    is(scalar(() = $said =~ /^5 /mg), 2, 'an empty line draws nothing, and board draws the board again');
};

subtest 'save and load' => sub {
    my $dir = File::Temp->newdir;
    my $file = "$dir/game.txt";
    my ($said, $t) = sitting([ 'd2-e3A', 'e5-f4A', "save $file" ]);
    like($said, qr/^Saved to \Q$file\E\.$/m, 'saved');
    my @moves = $t->game->moves;

    ($said, $t) = sitting([ "load $file" ]);
    like($said, qr/^Loaded \Q$file\E: 2 moves\.$/m, 'loaded');
    is_deeply([ $t->game->moves ], \@moves, 'the same two moves');
    is($t->game->position, Game::Fanorona->new(script => \@moves)->position, 'and the same position');

    ($said, $t) = sitting([ 'd2-e3A', "load $dir/absent.txt" ]);
    like($said, qr/^Cannot read \Q$dir\E\/absent\.txt: /m, 'a file that is not there');
    is($t->game->ply, 1, 'leaves the game alone');

    open my $fh, '>', "$dir/bad.txt" or die $!;
    print {$fh} "this is not a game\n";
    close $fh;
    ($said, $t) = sitting([ 'd2-e3A', "load $dir/bad.txt" ]);
    like($said, qr/bad\.txt is not a game of fanorona: /, 'and a file that is not a game');
    is($t->game->ply, 1, 'leaves it alone too');
    ok(!$T->new(interactive => 0, picking => 0, out => FnCapture->handle(\my $sink))->load("$dir/bad.txt"),
        'load returns false for it');
    ($said, $t) = sitting([ 'save', 'load' ]);
    like($said, qr/^save takes the name of a file\.$/m, 'save with no name');
    like($said, qr/^load takes the name of a file\.$/m, 'load with no name');
};

subtest 'the quiet count appears once half the limit has gone' => sub {
    my $variant = board_of('8b/9/9/9/w8 w', quiet_limit => 6, repeat => 0);
    my ($said, $t) = sitting([ 'a1-a2', 'i5-i4', 'a2-a3' ], variant => $variant);
    unlike($said, qr/Nothing taken for/, 'three of six: not yet');
    ($said, $t) = sitting([ 'a1-a2', 'i5-i4', 'a2-a3', 'i4-i3' ], variant => $variant);
    like($said, qr/^3  O-+.*   Nothing taken for 4 of 6$/m, 'four of six: beside the middle row');
};

# A WINDOW TOO NARROW SAYS SO, and says the number it needs. That number is the
# longest line of the drawing it would have made, counted here a second time.
subtest 'a window that is too narrow' => sub {
    my $wide = $T->new(interactive => 0, colour => 0, unicode => 0, picking => 0);
    my ($need) = sort { $b <=> $a } map { length } @{ $wide->board_lines };
    is($need, 65, 'the big board is 65 columns wide: 2 for the rank, 35 of board, 3 of gap, 25 of counts');
    my $t = $T->new(interactive => 0, colour => 0, unicode => 0, picking => 0, width => $need - 1);
    my $screen = join "\n", @{ $t->screen('plain') };
    like($screen, qr/This window is 64 columns wide and the board needs 65\./, 'one column short: it says both numbers');
    unlike($screen, qr/^5 /m, 'and draws no board');
    $t->width($need);
    like(join("\n", @{ $t->screen('plain') }), qr/^5  X-/m, 'at exactly the width it needs, the board');
    my $colour = $T->new(interactive => 0, colour => 1, unicode => 0, picking => 0, width => $need,
        out => FnCapture->handle(\my $sink));
    like(join("\n", @{ $colour->screen('plain') }), qr/^5 .*X/m, 'and the paint is not counted as width');
};

# COLOUR. The painted board is the lettered one with paint on it: strip the
# paint and the same characters are in the same columns.
subtest 'the painted board' => sub {
    my %arg = (interactive => 0, picking => 0, human => 'both');
    my $sink = '';
    my $plain = $T->new(%arg, colour => 0, unicode => 0);
    my $out = FnCapture->handle(\$sink);
    my $painted = $T->new(%arg, colour => 1, unicode => 0, out => $out);
    $_->command('d3-e3A') for $plain, $painted;
    my @lettered = @{ $plain->board_lines };
    my @coloured = @{ $painted->board_lines };
    isnt($coloured[4], $lettered[4], 'colour changes the line');
    (my $stripped = join "\n", @coloured) =~ s/\e\[[0-9;]*m//g;
    $stripped =~ s/[ ]+$//mg;
    is($stripped, join("\n", @lettered), 'and under the paint it is the same drawing');
    my $ground = $Game::Fanorona::Terminal::GROUND{trail};
    my $ink = $Game::Fanorona::Terminal::INK{trail};
    like($coloured[4], qr/\e\[\Q$ground;$ink\Em:\e\[0m/, 'the frame of the last move is painted in its own ground and ink');
    like($coloured[4], qr/\e\[\Q$Game::Fanorona::Terminal::GROUND{board};$Game::Fanorona::Terminal::INK{black}\EmX/,
        'and a black stone in black on the board');

    my $wide = $T->new(%arg, colour => 0, unicode => 1, out => FnCapture->handle(\my $unread));
    my $row = $wide->board_lines->[4];
    like($row, qr/\x{25CB}/, 'with unicode, White is a ring');
    like($row, qr/\x{25CF}/, 'and Black a disc: two shapes, not one shape in two colours');
    isnt($Game::Fanorona::Terminal::GLYPH{$_}{white}, $Game::Fanorona::Terminal::GLYPH{$_}{black}, "$_: the two stones are different characters")
        for qw(wide ascii);
};

# EVERY MARK CAN BE SEEN. A sibling drew its last move in a colour laid over
# another colour and it was on every board and visible on none. So: a mark is
# brackets first, which need no colour, and the colours are measured. The
# distance is the plain one between two colours in CIE Lab. The floors:
#
#   60  a frame's ink from the ground it is written on
#   50  a stone from every ground it can stand on
#   35  a mark's ground from the board's, and from every other mark's
#   25  the lines of the board from the board
#
# 50 and not 60 for the stones because both a white and a black stone must
# read on one ground, and the best a single ground does for the worse of the
# two is in the fifties.
subtest 'every mark, measured' => sub {
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
    my %ground = map { $_ => $number->($Game::Fanorona::Terminal::GROUND{$_}) } keys %Game::Fanorona::Terminal::GROUND;
    my %ink = map { $_ => $number->($Game::Fanorona::Terminal::INK{$_}) } keys %Game::Fanorona::Terminal::INK;

    cmp_ok($apart->(220, 222), '<', 60, 'the measure calls gold on pale yellow too close, as a sibling found it was');
    cmp_ok($apart->(16, 231), '>', 99, 'and black from white as far as it goes');

    my @marks = qw(cursor moving reach taken trail approach withdrawal);
    is_deeply([ sort keys %Game::Fanorona::Terminal::FRAME ], [ sort @marks ], 'seven marks, and each has brackets');
    for my $mark (@marks) {
        ok(exists $ground{$mark}, "$mark has a ground") or next;
        my $far = $apart->($ink{$mark}, $ground{$mark});
        cmp_ok($far, '>=', 60, sprintf('the brackets of %s on its ground: %.0f apart', $mark, $far));
        $far = $apart->($ground{$mark}, $ground{board});
        cmp_ok($far, '>=', 35, sprintf('the ground of %s from the board: %.0f', $mark, $far));
        my ($open, $close) = @{ $Game::Fanorona::Terminal::FRAME{$mark} };
        ok($open ne '-' && $open ne ' ' && $close ne '-' && $close ne ' ', "the brackets of $mark are not the line or a gap: $open $close");
    }
    my %same = (approach => 'taken', taken => 'approach');
    for my $one (@marks) {
        for my $two (grep { $_ gt $one } @marks) {
            next if ($same{$one} // '') eq $two;
            my $far = $apart->($ground{$one}, $ground{$two});
            cmp_ok($far, '>=', 35, sprintf('%s from %s: %.0f', $one, $two, $far));
        }
    }
    is($ground{approach}, $ground{taken}, 'approach is drawn as taken, which is what it asks about');
    isnt($ground{approach}, $ground{withdrawal}, 'and withdrawal is not');

    for my $stone (qw(white black)) {
        for my $where (qw(board cursor moving trail)) {
            my $far = $apart->($ink{$stone}, $ground{$where});
            cmp_ok($far, '>=', 50, sprintf('a %s stone on %s: %.0f', $stone, $where, $far));
        }
    }
    # A mutation run found this missing: with both stones written in black
    # every stone still stood out from every ground, and nothing above failed.
    my $between = $apart->($ink{white}, $ink{black});
    cmp_ok($between, '>=', 90, sprintf('the two stones from each other: %.0f', $between));
    cmp_ok(($lab->($ink{white}))[0], '>', ($lab->($ink{black}))[0] + 50, 'and White is much the lighter of the two');

    my $far = $apart->($ink{line}, $ground{board});
    cmp_ok($far, '>=', 25, sprintf('the lines on the board: %.0f', $far));

    my %frames;
    $frames{ join '', @{ $Game::Fanorona::Terminal::FRAME{$_} } }++ for qw(cursor moving reach taken trail);
    is(scalar(keys %frames), 5, 'the five marks a board can carry at once have five different brackets');
};

subtest 'what new refuses' => sub {
    ok(!eval { $T->new(human => 'red', interactive => 0); 1 }, 'a side that is not one');
    like($@, qr/side is white, black, both or neither, not 'red'/, 'with the reason');
    ok(!eval { $T->new(level => 6, interactive => 0); 1 }, 'a level that is not one');
    like($@, qr/level is 1 to 5/, 'with the reason');
    ok(!eval { $T->new(variant => 'chess', interactive => 0); 1 }, 'a board that is not one');
};

# TYPED PLAY ON A TERMINAL SCROLLS. The donor of this file cleared the screen
# before every board, which wiped the line saying what had just been played
# and whatever a command had answered. Typed play is a transcript: nothing in
# it moves the cursor.
subtest 'typed play never clears what was said' => sub {
    my ($said, $t) = sitting([ 'd2-e3A', 'level 2', 'new', 'd3-e3A', 'resign' ], interactive => 1, width => 100);
    unlike($said, qr/\e/, 'no escape of any kind, on a terminal with the keys turned off');
    # a terminal echoes what is typed, newline and all, so here nothing does:
    # what follows a prompt is on the prompt's line
    like($said, qr/^white> White played d2-e3A/m, 'and the line typed is not written a second time');
    like($said, qr/White played d2-e3A, taking 2 stones\.$/m, 'so the move is still there to read');
    like($said, qr/A new game\.$/m, 'and what a command said');
    like($said, qr/^Black resigns\. White wins\.$/m, 'to the end');
    ($said, $t) = sitting([ 'board' ], interactive => 1, width => 40);
    is(scalar(() = $said =~ /This window is 40 columns wide and the board needs 65\./mg), 2, 'and a narrow one is told so in place of each board');
};

subtest 'it writes where it was told to, and nowhere else' => sub {
    open my $keep_out, '>&', \*STDOUT or die $!;
    open my $keep_err, '>&', \*STDERR or die $!;
    my $dir = File::Temp->newdir;
    open STDOUT, '>', "$dir/out" or die $!;
    open STDERR, '>', "$dir/err" or die $!;
    my ($said) = sitting([ 'd2-e3A', 'moves', 'nonsense', 'hint', 'quit' ]);
    close STDOUT;
    close STDERR;
    open STDOUT, '>&', $keep_out or die $!;
    open STDERR, '>&', $keep_err or die $!;
    cmp_ok(length $said, '>', 500, 'the sitting said plenty, on its own handle');
    is(-s "$dir/out", 0, 'and nothing on STDOUT');
    is(-s "$dir/err", 0, 'and nothing on STDERR');
};

done_testing();
