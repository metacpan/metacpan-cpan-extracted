use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use FnCapture;

use Game::Fanorona;
use Game::Fanorona::Bot;
use Game::Fanorona::Terminal;
my $T = 'Game::Fanorona::Terminal';

# THE TERMINAL, PLAYED WITH THE ARROW KEYS. A key source stands in for the
# keyboard and hands over one character a call, exactly as a terminal does: an
# arrow is three characters and escape is one. Every screen the terminal draws
# starts by sending the cursor home, so what it wrote splits into the frames a
# person would have seen, in order.
#
# Nothing here needs Term::ReadKey, a terminal or a shell.

my %KEY = (up => "\e[A", down => "\e[B", right => "\e[C", left => "\e[D",
           enter => "\r", tab => "\t", backtab => "\e[Z", esc => "\e", back => "\x7f",
           home => "\e[H", end => "\e[F");

sub keys_of { join '', map { exists $KEY{$_} ? $KEY{$_} : $_ } @_ }

sub sitting {
    my ($keys, %with) = @_;
    my @chars = split //, keys_of(@$keys);
    my $written = '';
    my $out = FnCapture->handle(\$written);
    my $terminal = $T->new(
        out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1, pause => 0,
        human => 'both',
        keysource => sub { @chars ? shift @chars : undef },
        %with,
    );
    my $status = $terminal->start;
    close $out;
    my @frames = split /\e\[H/, $written;
    shift @frames;
    s/\e\[[0-9;?]*[A-Za-z]//g for @frames;
    return (\@frames, $terminal, $status, $written);
}

sub board_of { { cols => 9, rows => 5, start => $_[0], @_[1 .. $#_] } }

sub row {
    my ($frame, $rank) = @_;
    my ($row) = $frame =~ /^($rank [^\n]*)$/m;
    return $row // '';
}

# every bracketed point of a frame, as "mark@point": the column says the file
sub marked {
    my ($frame) = @_;
    my @found;
    for my $rank (reverse 1 .. 5) {
        my $row = row($frame, $rank);
        for my $file (0 .. 8) {
            my $cell = substr $row . (' ' x 40), 2 + 4 * $file, 3;
            push @found, $cell . '@' . chr(97 + $file) . $rank if $cell =~ /\A[\[<({:].[\]>)}:]\z/;
        }
    }
    return join ' ', @found;
}

#    5  +---+---+---+---+---+---X---+---+       White: b4 and h3.
#    4  +---O---+---+---+---+---+---+---+       Black: g5, f3, i3, f2, h1.
#    3  +---+---+---+---+---X---+---O---X
#    2  +---+---+---+---+---X---+---+---+       h3 steps left to g3, a strong
#    1  +---+---+---+---+---+---+---X---+       point. Ahead of it then is f3,
#                                               and behind it is i3: the step
# takes either, and not both. From g3 two more steps take: up to g4, which
# comes up to g5, and up-right to h4, which draws away from f2. (h3 can also
# step down to h2 and take h1; no test here uses that.) (h3 can also
# step down to h2 and take h1; no test here uses that.)
my $CHAIN = '6b2/1w7/5b1wb/5b3/7b1 w';

subtest 'the cursor walks the stones that can move, and only those' => sub {
    my ($frames, $t) = sitting([ ('tab') x 4, 'backtab', 'end', 'home', 'q' ]);
    is(scalar(@$frames), 8, 'eight frames: the first, and one a key');
    is_deeply($t->lit, [qw(d3 d2 e2 f2)], 'four stones can move at the set-up, top row first, then left to right');
    my @cursor = map { join ',', map { /\A\[.\]\@(..)\z/ ? $1 : () } split / /, marked($_) } @$frames;
    is("@cursor", 'd3 d2 e2 f2 d3 f2 f2 d3', 'tab goes round them in the order they are drawn, and back; end and home');
    is(row($frames->[0], 3), '3  X---O---X--[O]-(+)--X---O---X---O', 'the cursor is on d3 and the point it can step to is lit');
    is(marked($frames->[1]), '(+)@e3 [O]@d2', 'on d2, the same point, lit for d2');
    like($frames->[0], qr/arrows choose a stone   enter pick it up/, 'and the foot of the screen says what the keys do');
    is($t->game->ply, 0, 'nothing was played');
    is($t->raw, 0, 'and the keyboard was handed back at the end');

    ($frames, $t) = sitting([ 'down', 'right', 'right', 'right', 'left', 'up', 'down', 'q' ]);
    @cursor = map { join ',', map { /\A\[.\]\@(..)\z/ ? $1 : () } split / /, marked($_) } @$frames;
    is("@cursor", 'd3 d2 e2 f2 f2 e2 d3 d2', 'the arrows: the nearest lit stone that way, and nowhere when there is none');

    ($frames, $t) = sitting([ 'right', 'left', 'q' ], variant => board_of($CHAIN));
    is_deeply($t->lit, ['h3'], 'when a stone can take, only stones that can take are lit: h3, and not b4');
    is(marked($frames->[2]), '(+)@g3 [O]@h3 (+)@h2', 'and no key walks the cursor onto b4');
};

subtest 'steer: the nearest in a direction, the diagonals too' => sub {
    my $t = $T->new(interactive => 0, picking => 0);
    is($t->steer('d3', 'right', [qw(e3 g3 d4)]), 'e3', 'right: the nearer of two on the row');
    is($t->steer('d3', 'up', [qw(a5 d4 d5)]), 'd4', 'up: the nearer of two on the file, not the one off to the side');
    is($t->steer('d3', 'left', [qw(e3 g3)]), 'd3', 'nothing that way: it stays where it is');
    is($t->steer('d3', '9', [qw(e4 d4 c2)]), 'e4', '9 is up and to the right');
    is($t->steer('d3', 'y', [qw(e4 c4 c2)]), 'c4', 'y up and to the left');
    is($t->steer('d3', 'b', [qw(e4 c4 c2)]), 'c2', 'b down and to the left');
    is($t->steer('d3', 'n', [qw(e4 c4 e2)]), 'e2', 'n down and to the right');
    is($t->steer('d3', 'u', [qw(e4 d4 c2)]), 'd3', 'and u is no direction: it is undo');
    is($t->steer('d3', '2', [qw(e4 d1 c2)]), 'd1', '2 is down');
    is($t->steer('d3', 'x', [qw(e4 d1 c2)]), 'd3', 'a key that is no direction goes nowhere');
};

subtest 'a chain built a step at a time, with a step that takes two ways in it' => sub {
    my @keys = ('enter', '4', 'x', 'enter', 'a', '8', 'back', '9', 'enter', 'q');
    my ($frames, $t) = sitting(\@keys, variant => board_of($CHAIN));
    is(scalar(@$frames), 10, 'a frame a key');

    is(marked($frames->[0]), '(+)@g3 [O]@h3 (+)@h2', 'first: the cursor on h3, and the two points it can step to');
    is(marked($frames->[1]), '(+)@g3 <O>@h3 (+)@h2', 'enter: h3 is picked up');
    like($frames->[1], qr/^Choose where the stone at h3 goes\.$/m, 'and it says so');

    is(row($frames->[2], 3), '3  +---+---+---+---+--{a}-(+)-<O>-{w}', 'left: THE STEP TAKES TWO WAYS, so both rows are shown, a ahead and w behind');
    like($frames->[2], qr/^a take 1 stone ahead   w take 1 stone behind   esc neither$/m, 'and the question is asked');
    is(row($frames->[2], 5), '5  +---+---+---+---+---+---X---+---+    Black X   5 left  taken 0', 'with nothing taken yet');
    is($frames->[3], $frames->[2], 'a key that answers nothing leaves the question standing');
    is($frames->[4], $frames->[2], 'and so does enter: it never chooses for the player');

    is(row($frames->[5], 3), '3  +---+---+---+---+--{*}-<O>-:+:--X', 'a: THE BOARD IS THE RESULT. The stone is on g3, f3 is gone and marked, i3 stands');
    is(row($frames->[5], 5), '5  +---+---+---+---+---+---X---+---+    Black X   4 left  taken 0', 'the count beside the board is of that board: four left');
    is(row($frames->[5], 1), '1  +---+---+---+---+---+---+---X---+    White O   2 left  taken 1', 'and one taken');
    is(marked($frames->[5]), '(+)@g4 (+)@h4 {*}@f3 <O>@g3 :+:@h3', 'the two steps that take from here are lit');
    like($frames->[5], qr/^So far h3-g3A, taking 1 stone\.$/m, 'the move so far, written out');
    like($frames->[5], qr/^arrows choose the next step   enter play it   backspace one step back   esc start again$/m, 'and the keys now');

    is(row($frames->[6], 5), '5  +---+---+---+---+---+--{*}--+---+    Black X   3 left  taken 0', 'up: g5 is taken too');
    is(row($frames->[6], 4), '4  +---O---+---+---+---+--<O>--+---+', 'the stone is on g4');
    like($frames->[6], qr/^So far h3-g3A-g4A, taking 2 stones\.$/m, 'two steps, two stones');
    unlike($frames->[6], qr/choose the next step/, 'no step takes from g4, so the foot no longer offers one');

    is($frames->[7], $frames->[5], 'BACKSPACE TAKES BACK ONE STEP, and the screen is the one before it exactly');

    is(row($frames->[8], 4), '4  +---O---+---+---+---+---+--<O>--+', 'u: a different second step, up and right to h4');
    is(row($frames->[8], 2), '2  +---+---+---+---+--{*}--+---+---+', 'which draws away from f2 and takes it');
    is(row($frames->[8], 5), '5  +---+---+---+---+---+---X---+---+    Black X   3 left  taken 0', 'g5 stands again');
    like($frames->[8], qr/^So far h3-g3A-h4W, taking 2 stones\.$/m, 'written out');
    is($t->game->ply, 1, 'enter played it') ;
    is_deeply([ $t->game->moves ], ['h3-g3A-h4W'], 'as one move of two steps');
    is($t->game->position, '6b2/1w5w1/8b/9/7b1 b', 'and the position is the one that was shown');
    like($frames->[9], qr/^White played h3-g3A-h4W, taking 2 stones\.$/m, 'the next screen says what was played');
    is(row($frames->[9], 3), '3  +---+---+---+---+--:*:-:+:-:+:--X', 'and frames it: the points the stone stood on, and f3 that it took');
};

# THE STEPS ABOVE AND BELOW ARE MADE WITH THE NUMERIC PAD, one key a step: 4 is
# left, 8 up, 6 right, 2 down. The arrows do something else once a stone is
# picked up, and this is it.
#
# THE OWNER, playing the first game in a real terminal: "No way of using the
# arrow keys to play a diagonal move." There was not: an arrow stepped the
# stone at once, so only four directions had an arrow. Now the arrows move a
# cursor over the points the stone may step to and Enter steps there.
subtest 'the arrows reach every point a stone can step to, the diagonal ones too' => sub {
    my @keys = ('enter', 'left', 'enter', 'a', 'up', 'right', 'left', 'right', 'down', 'enter', 'enter', 'q');
    my ($frames, $t) = sitting(\@keys, variant => board_of($CHAIN));
    is(scalar(@$frames), 12, 'a frame a key');
    is(marked($frames->[2]), '[+]@g3 <O>@h3 (+)@h2', 'left: the cursor is on g3, and THE STONE HAS NOT MOVED');
    like($frames->[2], qr/^Enter steps to g3\.$/m, 'and the screen says what enter will do');
    like($frames->[2], qr/^enter step there   arrows choose another point   backspace not there   esc start again$/m, 'and what the other keys will');
    like($frames->[3], qr/^a take 1 stone ahead   w take 1 stone behind   esc neither$/m, 'enter steps there: and that step takes two ways, so it asks');
    is(marked($frames->[4]), '(+)@g4 (+)@h4 {*}@f3 <O>@g3 :+:@h3', 'a: stepped, with the cursor on no point');
    is(marked($frames->[5]), '[+]@g4 (+)@h4 {*}@f3 <O>@g3 :+:@h3', 'up: the cursor is on g4, straight up');
    is(marked($frames->[6]), '(+)@g4 [+]@h4 {*}@f3 <O>@g3 :+:@h3', 'RIGHT, AND IT IS ON h4: up and to the right of the stone, a diagonal');
    is(marked($frames->[7]), '[+]@g4 (+)@h4 {*}@f3 <O>@g3 :+:@h3', 'left: back to g4');
    is(marked($frames->[8]), '(+)@g4 [+]@h4 {*}@f3 <O>@g3 :+:@h3', 'right again');
    is($frames->[9], $frames->[8], 'down: no lit point is that way from h4, and the cursor stays');
    like($frames->[10], qr/^So far h3-g3A-h4W, taking 2 stones\.$/m, 'enter: the stone steps to h4, the diagonal, and takes by withdrawal');
    unlike($frames->[10], qr/Enter steps to/, 'and the cursor is on no point again');
    is($t->game->ply, 1, 'so the next enter plays the move');
    is_deeply([ $t->game->moves ], ['h3-g3A-h4W'], 'which is the one that was built with the arrows alone');

    ($frames, $t) = sitting([ 'down', 'enter', 'up', 'q' ]);
    is(marked($frames->[2]), '(+)@e3 <O>@d2', 'd2 picked up at the set-up: its one step is up and to the right');
    is(marked($frames->[3]), '[+]@e3 <O>@d2', 'UP ALONE FINDS IT, there being nothing straight up');
    ($frames, $t) = sitting([ 'down', 'enter', 'right', 'enter', 'enter', 'q' ]);
    is_deeply([ $t->game->moves ], ['d2-e3A'], 'and so does right; enter steps, enter plays');

    # THE OWNER AGAIN: "You should be able to commit with space as well as
    # enter." Space picked a stone up and did nothing after that.
    my ($entered) = sitting([ 'enter', 'left', 'enter', 'a', 'up', 'right', 'enter', 'enter', 'q' ], variant => board_of($CHAIN));
    ($frames, $t) = sitting([ ' ', 'left', ' ', 'a', 'up', 'right', ' ', ' ', 'q' ], variant => board_of($CHAIN));
    is_deeply([ $t->game->moves ], ['h3-g3A-h4W'], 'SPACE PICKS UP, STEPS AND PLAYS: the same move built with no enter at all');
    is_deeply($frames, $entered, 'and every screen on the way is the one enter gives');
    ($frames, $t) = sitting([ ' ', 'left', ' ', ' ', 'x', 'q' ], variant => board_of($CHAIN));
    is($frames->[4], $frames->[3], 'space does not answer the question a step asks, any more than enter does');
    is($t->game->ply, 0, 'and plays nothing there');

    ($frames, $t) = sitting([ 'enter', 'left', 'enter', 'a', 'up', 'back', 'back', 'q' ], variant => board_of($CHAIN));
    is($frames->[6], $frames->[4], 'backspace with the cursor on a point takes the cursor off, and no step back');
    is(marked($frames->[7]), '(+)@g3 <O>@h3 (+)@h2', 'and the next backspace takes the step back');

    ($frames, $t) = sitting([ 'enter', 'up', 'q' ], variant => board_of($CHAIN));
    like($frames->[2], qr/^A stone can be taken, so one must be\.$/m, 'an arrow with no lit point that way says why the point there is not lit');
    unlike($frames->[2], qr/Enter steps to/, 'and puts the cursor nowhere');

    ($frames, $t) = sitting([ 'enter', 'left', 'esc', 'q' ], variant => board_of($CHAIN));
    is($frames->[3], $frames->[0], 'escape with the cursor on a point puts the stone down');
    is($t->game->ply, 0, 'and nothing was played in any of that');
};

subtest 'the other answer, and no answer' => sub {
    my ($frames, $t) = sitting([ 'enter', '4', 'w', 'enter', 'q' ], variant => board_of($CHAIN));
    is(row($frames->[3], 3), '3  +---+---+---+---+---X--<O>-:+:-{*}', 'w: i3 is taken, behind the stone, and f3 stands');
    is_deeply([ $t->game->moves ], ['h3-g3W'], 'enter plays the one step: a player may stop');

    ($frames, $t) = sitting([ 'enter', '4', 'esc', 'q' ], variant => board_of($CHAIN));
    is(marked($frames->[3]), '(+)@g3 <O>@h3 (+)@h2', 'escape answers neither: the stone is back on h3, still picked up');
    is($t->game->ply, 0, 'and nothing is played');

    ($frames, $t) = sitting([ 'enter', '4', 'a', '4', 'q' ], variant => board_of($CHAIN));
    like($frames->[4], qr/^A stone may not step twice running in the same direction\.$/m, 'a step the rules refuse is refused with the rule');
    is(row($frames->[4], 3), row($frames->[3], 3), 'and the board does not change');

    ($frames, $t) = sitting([ 'enter', '4', 'a', '4', 'tab', 'q' ], variant => board_of($CHAIN));
    unlike($frames->[5], qr/twice running/, 'the refusal is gone at the next key');
    like($frames->[5], qr/^That key does nothing here\. Press \? for the ones that do\.$/m, 'and a key with no meaning is told so');

    ($frames, $t) = sitting([ 'enter', '4', 'a', '6', '2', 'q' ], variant => board_of($CHAIN));
    like($frames->[4], qr/^A stone may not come back to a point in the same move\.$/m, 'back to h3, where it started: refused with that rule');
    like($frames->[5], qr/^A stone that has taken may stop, and may not then move on without taking\.$/m, 'and down to g2, which would take nothing, with that one');

    ($frames, $t) = sitting([ 'enter', '6', 'a', '8', 'q' ]);
    like($frames->[4], qr/^The move is complete, and enter plays it\.$/m, 'a step after the last one there is: it says the move is whole');
    is($t->game->ply, 0, 'and still plays nothing until enter');
};

subtest 'enter plays a move and nothing less; backspace and escape' => sub {
    my ($frames, $t) = sitting([ 'enter', 'enter', 'enter', 'q' ], variant => board_of($CHAIN));
    is($t->game->ply, 0, 'ENTER ON A STONE THAT HAS NOT STEPPED PLAYS NOTHING');
    is($frames->[2], $frames->[1], 'and changes nothing on the screen');
    unlike($frames->[3], qr/not a move|White played/, 'nor is anything refused: there was nothing to refuse');

    ($frames, $t) = sitting([ 'enter', 'back', 'q' ], variant => board_of($CHAIN));
    is($frames->[2], $frames->[0], 'backspace with no step taken puts the stone down');

    ($frames, $t) = sitting([ 'enter', '4', 'a', '8', 'esc', 'q' ], variant => board_of($CHAIN));
    is($frames->[5], $frames->[0], 'ESCAPE TAKES THE WHOLE MOVE BACK: two steps in, and the screen is the first one');
    is($t->game->ply, 0, 'nothing played');
    is($t->game->position, $CHAIN, 'and the game itself was never touched');

    ($frames, $t) = sitting([ 'enter', '4', 'a', '8', 'back', 'back', 'back', 'q' ], variant => board_of($CHAIN));
    is($frames->[5], $frames->[3], 'one backspace: one step');
    is($frames->[6], $frames->[1], 'two: both, and the stone is still picked up');
    is($frames->[7], $frames->[0], 'three: put down');
};

# A PERSON WATCHES THEIR OWN MOVE. One stone, one step, and nothing else the
# rules allow: it is still not played until enter is pressed.
subtest 'the only move there is, is not played for the player' => sub {
    my $one = board_of('9/9/w1b6/9/9 w');
    is(scalar(Game::Fanorona->new(variant => $one)->legal), 1, 'a position with exactly one legal move');
    my ($frames, $t) = sitting([ 'enter', '6', 'q' ], variant => $one);
    is($t->game->ply, 0, 'picked up and stepped, it is not played');
    is(marked($frames->[2]), ':+:@a3 <O>@b3 {*}@c3', 'it is shown, taken stone and all');
    like($frames->[2], qr/^enter play it   backspace one step back   esc start again$/m, 'with enter offered and no further step');

    ($frames, $t) = sitting([ 'enter', '6', 'enter', 'n', 'q' ], variant => $one);
    like($frames->[3], qr/^Black has no stone left\. White wins\.$/m, 'enter plays it, and the game is over');
    like($frames->[3], qr/^n new game   u undo   r redo   R rules   : command   q quit$/m, 'with the keys for a game that is over');
    is($t->game->ply, 0, 'n starts another');
    is(marked($frames->[4]), '[O]@a3 (+)@b3', 'and the cursor is on the board again');
};

subtest 'what the other side did stays on the screen' => sub {
    my ($frames, $t) = sitting([ 'enter', '6', 'a', 'enter', 'tab', 'enter', 'q' ]);
    is($t->game->ply, 1, 'White played');
    my @after = @{$frames}[ 4 .. $#$frames ];
    is(scalar(@after), 3, "three of Black's screens: choosing, the next stone, picked up");
    is(scalar(grep { /^White played d3-e3A, taking 1 stone\.$/m } @after), 3, "and White's move is written on every one");

    ($frames, $t) = sitting([ 'enter', '6', 'a', 'enter', 'q' ], human => 'white', level => 2);
    is($t->game->ply, 2, 'against the program: it answered');
    my $reply = ($t->game->moves)[1];
    like($frames->[-1], qr/^Black played \Q$reply\E/m, "and its move is what is written above the board: $reply");
    like(join('', @$frames), qr/^The program is thinking\.$/m, 'having said it was thinking');
};

subtest 'the hint' => sub {
    my $hint = Game::Fanorona::Bot->hint(Game::Fanorona->new)->{move};
    my ($frames, $t) = sitting([ 'h', 'q' ]);
    like($frames->[1], qr/^The program would play \Q$hint\E\. Enter plays it; escape puts the stone back\.$/m, "h: $hint");
    like($frames->[1], qr/^So far \Q$hint\E/m, 'built on the board as a move');
    is($t->game->ply, 0, 'and not played');

    ($frames, $t) = sitting([ 'h', 'esc', 'q' ]);
    is($t->game->ply, 0, 'escape after a hint plays nothing');
    like($frames->[2], qr/arrows choose a stone/, 'and the cursor is choosing again');

    ($frames, $t) = sitting([ 'h', 'enter', 'q' ]);
    is_deeply([ $t->game->moves ], [$hint], 'enter after a hint plays it');
};

subtest 'help, the rules and a typed command' => sub {
    my ($frames, $t) = sitting([ '?', 'x', 'R', 'x', 'q' ]);
    like($frames->[1], qr/^  backspace   take the cursor off a point; then take back one step$/m, '? lists the keys');
    like($frames->[1], qr/^Any key goes back\.$/m, 'and says how to leave');
    is($frames->[2], $frames->[0], 'any key does');
    like($frames->[3], qr/TAKING BY WITHDRAWAL/, 'R gives the rules');

    ($frames, $t) = sitting([ ':', split(//, 'resigm'), 'back', 'n', 'enter', 'q' ]);
    is($t->game->result->how, 'resign', 'a colon takes a command, backspace corrects it, enter does it');
    like($frames->[-1], qr/^White resigns\. Black wins\.$/m, 'and the board says so');

    ($frames, $t) = sitting([ ':', split(//, 'level 5'), 'enter', 'q' ]);
    is($t->level, 5, 'level 5, typed');
    like($frames->[-1], qr/^Level 5: the program the strongest here\.$/m, 'answered above the board');
};

subtest 'the menu' => sub {
    my ($frames, $t) = sitting([ 'right', 'down', 'right', 'right', 'down', 'left', 'enter', 'q' ], menu => 1, human => 'white');
    like($frames->[0], qr/^> side     < white >$/m, 'it opens on the side, white');
    like($frames->[0], qr/^  level    < 3 >   looks ahead, and misses things$/m, 'the level, 3, and what that means');
    like($frames->[0], qr/^  variant  < sivy >$/m, 'and the board');
    like($frames->[1], qr/^> side     < black >$/m, 'right changes the side');
    like($frames->[4], qr/^> level    < 5 >   the strongest here$/m, 'down, right, right: level 5');
    like($frames->[6], qr/^> variant  < telo >$/m, 'down, left: round to the last board, telo');
    is($t->human, 'black', 'enter: Black');
    is($t->level, 5, 'level 5');
    is($t->game->variant->name, 'telo', 'on three by three');
    is($t->game->ply, 1, 'and the program, as White, has moved first');

    ($frames, $t) = sitting(['q'], menu => 1);
    is(scalar(@$frames), 1, 'q at the menu stops before a board is drawn');
    is($t->game->ply, 0, 'with nothing played');
};

subtest 'a window too narrow to draw in' => sub {
    my ($frames, $t) = sitting([ 'enter', '6', 'a', 'enter', 'q', 'enter' ], width => 50);
    like($frames->[0], qr/^This window is 50 columns wide and the board needs 65\. Widen it and press a key, or q to stop\.$/m, 'it says what it needs');
    unlike($frames->[0], qr/^5 /m, 'and draws no board');
    is($t->game->ply, 0, 'KEYS PRESSED BLIND DO NOTHING: a move is not played on a board that cannot be seen');
    is(scalar(@$frames), 5, 'and q still stops');
};

subtest 'the keys run out' => sub {
    my ($frames, $t, $status) = sitting([ 'enter', '4' ], variant => board_of($CHAIN));
    is($status, 0, 'the end of the keys in the middle of a question ends the sitting quietly');
    is($t->raw, 0, 'with the keyboard handed back');
    is($t->game->ply, 0, 'and nothing played');
};

done_testing();
