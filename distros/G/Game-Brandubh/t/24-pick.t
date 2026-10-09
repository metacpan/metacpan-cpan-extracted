use strict;
use warnings;
use Test::More;

use Game::Brandubh;
use Game::Brandubh::Bot;
use Game::Brandubh::Terminal;
my $T = 'Game::Brandubh::Terminal';

# THE TERMINAL, PLAYED WITH THE ARROW KEYS. A key source stands in for the
# keyboard and hands over one character a call, exactly as a terminal does: an
# arrow is three characters and escape is one. Every screen the terminal draws
# starts by sending the cursor home, so what it wrote splits into the frames a
# person would have seen, in order.

my %KEY = (up => "\e[A", down => "\e[B", right => "\e[C", left => "\e[D",
           enter => "\r", tab => "\t", esc => "\e", back => "\x7f");

sub keys_of { join '', map { exists $KEY{$_} ? $KEY{$_} : $_ } @_ }

sub sitting {
    my ($keys, %with) = @_;
    my @chars = split //, keys_of(@$keys);
    my $written = '';
    open my $out, '>', \$written or die "out: $!";
    my $terminal = $T->new(
        out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1,
        seed => 'P' x 32, pause => 0,
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

sub board_row {
    my ($frame, $rank) = @_;
    my ($row) = $frame =~ /^( $rank \|[^\n]*)$/m;
    return $row // '';
}

subtest 'the first step offers the pieces that can move, and only those' => sub {
    my ($frames, $t) = sitting([ ('tab') x 8, 'q' ], human => 'both');
    is(scalar(@$frames), 9, 'nine frames: the first, and one a tab');
    is_deeply($t->movable, [qw(d1 d2 a4 b4 f4 g4 d6 d7)], 'the eight attackers, in board order');

    my @cursor;
    for my $frame (@$frames) {
        my @at = $frame =~ /\[(.)\]/g;
        push @cursor, join '', @at;
    }
    is(join(' ', @cursor), 'A A A A A A A A A', 'the cursor is on an attacker in every frame, and on one square only');
    is(board_row($frames->[0], 1), ' 1 | X | . | . |[A]| . | . | X |', 'it starts on d1, with the squares d1 could reach dotted');
    is(board_row($frames->[1], 2), ' 2 | . | . | . |[A]| . | . | . |', 'tab moves it to d2, and the dots with it');
    is(board_row($frames->[8], 1), ' 1 | X | . | . |[A]| . | . | X |', 'eight tabs bring it round to d1 again');
    like($frames->[0], qr/arrows choose a piece   enter pick it up/, 'and the foot of the screen says what the keys do');
    is($t->game->ply, 0, 'nothing was played');
    is($t->raw, 0, 'and the keyboard was handed back at the end');
};

subtest 'steer: the nearest in a direction' => sub {
    my $t = $T->new(interactive => 0, picking => 0, seed => 'P' x 32);
    is($t->steer('d4', 'right', [qw(e4 g4 d5)]), 'e4', 'right: the nearer of two on the row');
    is($t->steer('d4', 'up', [qw(a7 d6 d7)]), 'd6', 'up: the nearer of two on the file, not the one off to the side');
    is($t->steer('d4', 'left', [qw(e4 g4)]), 'd4', 'nothing that way: it stays where it is');
    is($t->steer('d1', 'up', [qw(d2 a4 g4)]), 'd2', 'straight up before diagonally up');
    is($t->steer('d2', 'left', [qw(a4 b4 d6)]), 'b4', 'left and a little up, when nothing is straight left');
    is($t->steer('a1', 'down', [qw(a2 b1)]), 'a1', 'off the board: it stays');
    is($t->steer('c3', 'right', [qw(c3 d3)]), 'd3', 'itself is not a candidate');
};

subtest 'the arrows walk the board' => sub {
    my ($frames, $t) = sitting([ 'up', 'up', 'left', 'down', 'q' ], human => 'both');
    my @where = map { my ($r) = $_ =~ /^ (\d) \|[^\n]*\[A\]/m; $r } @$frames;
    is(join(' ', @where), '1 2 6 4 2', 'from d1: up to d2, straight up over the king to d6, left and down to b4, and down to d2');
};

# THE SECOND STEP DRAWS THE BOARD THE MOVE WOULD MAKE: the piece on its new
# square, the square it left empty, and what it would capture struck out. A
# preview that only pointed at the destination would leave the player to work
# out the captures, which is the whole of the game.
subtest 'picking a piece up shows the board the move would leave' => sub {
    my $game = Game::Brandubh->new(position => '7/7/7/7/ad1da2/6k/2a4 a');
    my ($frames, $t) = sitting([ 'enter', 'up', 'up', 'enter', 'q' ], human => 'both', game => $game);

    my $picked = $frames->[1];
    is(board_row($picked, 1), ' 1 | X |(A)| _ | . | . | . | X |', 'picked up from c1: the first square it can reach, in brackets');
    like($picked, qr/The attacker from c1 to b1\./, 'and the move, in words, under the board');
    like($picked, qr/arrows choose where   enter play it   esc put it back/, 'with the keys of the second step');

    my $aimed = $frames->[3];
    is(board_row($aimed, 3), ' 3 | A | x |(A)| x | A |   |   |', 'aimed at c3: the attacker there, and BOTH defenders struck out');
    is(board_row($aimed, 1), ' 1 | X | . | _ | . | . | . | X |', 'c1 empty, where it came from');
    like($aimed, qr/The attacker from c1 to c3, taking b3 and d3\./, 'and the captures in words');

    is($t->game->ply, 1, 'enter plays it');
    is($t->game->shown->[0], 'c1-c3xb3,d3', 'the move that was shown');
    is($t->game->at('b3') . $t->game->at('d3'), '', 'and both defenders are gone');
};

subtest 'escape puts the piece back' => sub {
    my ($frames, $t) = sitting([ 'enter', 'right', 'esc', 'q' ], human => 'both');
    like($frames->[2], qr/esc put it back/, 'holding the piece');
    like($frames->[3], qr/enter pick it up/, 'after escape, choosing a piece again');
    is(board_row($frames->[3], 1), ' 1 | X | . | . |[A]| . | . | X |', 'with the cursor back on the piece that was held');
    is($t->game->ply, 0, 'and nothing played');

    ($frames, $t) = sitting([ 'enter', 'back', 'q' ], human => 'both');
    like($frames->[2], qr/enter pick it up/, 'backspace does the same');

    ($frames, $t) = sitting([ 'esc', 'esc', 'q' ], human => 'both');
    is($t->game->ply, 0, 'escape with nothing held does nothing, twice');
};

subtest 'a move that wins says so before it is played' => sub {
    my $game = Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 d');
    my ($frames, $t) = sitting([ 'enter', 'down', 'down', 'down', 'enter', 'q' ], human => 'both', game => $game);
    unlike($frames->[1], qr/This wins the game/, 'the first square offered does not win');
    like($frames->[4], qr/The king from a4 to a1\. This wins the game\./, 'the corner does, and the screen says so');
    is(board_row($frames->[4], 1), ' 1 |(K)|   |   | A |   |   | X |', 'with the king drawn on it');
    is($t->game->result->how, 'corner', 'enter, and the game is won');
    like($frames->[5], qr/The king has reached a corner\. The defenders win\./, 'the last screen says how');
    like($frames->[5], qr/n new game   u undo   r rules   q quit/, 'and what can be done now');
};

subtest 'a key that is not one is ignored, and not taken for enter' => sub {
    my ($frames, $t) = sitting([ "\e[9z", "\e[25~", "\eOQ", 'q' ], human => 'both');
    is($t->game->ply, 0, 'three escape sequences nobody knows: nothing was played');
    is(scalar(grep { /esc put it back/ } @$frames), 0, 'and no piece was picked up');
    unlike(join('', @$frames), qr/does nothing here/, 'nor is a function key scolded');

    ($frames, $t) = sitting([ 'z', 'z', 'q' ], human => 'both');
    is(scalar(() = join('', @$frames) =~ /That key does nothing here\. Press \? for the ones that do\./g), 2,
        'a letter that does nothing is told so, once, and the line stays up');
};

# THE PICKER REDRAWS THE WHOLE SCREEN ON EVERY KEY, so anything written once
# above the board is gone at the next keystroke unless it is held. What the
# program just played is held, until the person has answered it.
subtest 'what the program played stays on the screen until it is answered' => sub {
    my ($frames, $t) = sitting([ 'tab', 'tab', 'enter', 'esc', 'enter', 'enter', 'tab', 'q' ],
                               human => 'defenders', level => 1);
    my @told = map { my ($line) = $_ =~ /(The attackers played [^\n]*)/; $line } @$frames;
    my @picking = grep { $frames->[$_] =~ /choose a piece|choose where/ } 0 .. $#$frames;
    cmp_ok(scalar(@picking), '>=', 7, scalar(@picking) . ' screens were drawn while the person chose');

    my $first = $told[ $picking[0] ];
    like($first, qr/\AThe attackers played [a-g][1-7]-[a-g][1-7]/, 'the program moved first, and the first screen says what');
    my @before = @picking[0 .. 4];
    is(scalar(grep { defined $told[$_] && $told[$_] eq $first } @before), 5,
        'and the same line is on all five screens drawn before the person moved');

    is($t->game->ply, 3, 'the person moved, and the program answered');
    my $last = $told[ $picking[-1] ];
    like($last, qr/\AThe attackers played /, 'the screen after that tells the program\'s new move');
    isnt($last, $first, 'and not the old one');
};

subtest 'h shows the move the program would play, ready to be played' => sub {
    my $want = Game::Brandubh::Bot->hint(Game::Brandubh->new(seed => 'P' x 32), seed => 'P' x 32);
    my ($frames, $t) = sitting([ 'h', 'enter', 'q' ], human => 'both');
    my ($from, $to) = (substr($want, 0, 2), substr($want, 2, 2));
    like($frames->[1], qr/The program would play \Q$from-$to\E\. Enter to play it\./, 'the hint is written above the board');
    like($frames->[1], qr/The attacker from \Q$from\E to \Q$to\E/, 'and the piece is already picked up and aimed');
    is($t->game->log->[0], $want, 'enter plays exactly that move');
};

subtest 'the other keys' => sub {
    my ($frames, $t) = sitting([ '3', 'q' ], human => 'both');
    is($t->level, 3, '3 sets the level');
    like($frames->[1], qr/The program now plays at level 3\./, 'and says so on the screen');

    ($frames, $t) = sitting([ 'enter', 'right', 'enter', 'u', 'q' ], human => 'both');
    is($t->game->ply, 0, 'u takes the move back');
    like($frames->[-1], qr/Taken back\./, 'and says so');

    ($frames, $t) = sitting([ '?', 'x', 'q' ], human => 'both');
    like($frames->[1], qr/On the board, with the arrow keys:/, '? is the help page');
    like($frames->[1], qr/Press any key to go back to the board\./, 'which says how to leave it');
    like($frames->[2], qr/enter pick it up/, 'and any key goes back to the board');

    ($frames, $t) = sitting([ 'r', 'x', 'q' ], human => 'both');
    like($frames->[1], qr/Every piece moves like a rook/, 'r is the rules');

    ($frames, $t) = sitting([ ':', 'l', 'e', 'v', 'e', 'l', ' ', '1', 'enter', 'q' ], human => 'both');
    is($t->level, 1, ': takes a typed command');

    ($frames, $t) = sitting([ ':', 'l', 'x', 'back', 'e', 'v', 'e', 'l', ' ', '3', 'enter', 'q' ], human => 'both');
    is($t->level, 3, 'with backspace to rub a letter out');

    ($frames, $t) = sitting([ 'enter', 'right', 'enter', 'n', 'q' ], human => 'both');
    is($t->game->ply, 0, 'n starts a new game');
    like($frames->[-1], qr/A new game\./, 'and says so');

    my $painted;
    ($frames, $t, undef, $painted) = sitting([ 'c', 'q' ], human => 'both');
    like($painted, qr/\e\[48;5;33;/, 'c turns colour on, and the cursor has a ground of its own');
    is($t->colour, 1, 'and it stays on');
};

subtest 'the painted board: a ground for the cursor, the landing square and what is taken' => sub {
    my $game = Game::Brandubh->new(position => '7/7/7/7/ad1da2/6k/2a4 a');
    my (undef, undef, undef, $painted) = sitting([ 'enter', 'up', 'up', 'q' ],
        human => 'both', game => $game, colour => 1, unicode => 1);
    my @frames = split /\e\[H/, $painted;
    like($frames[1], qr/\e\[48;5;33;[0-9;]+m  \xE2\x96\xB2  \e\[0m/, 'choosing: the attacker under the cursor on the cursor\'s blue');
    like($frames[-1], qr/\e\[48;5;34;[0-9;]+m  \xE2\x96\xB2  \e\[0m/, 'aiming: the attacker on the landing square\'s green');
    is(scalar(() = $frames[-1] =~ /\e\[48;5;160;[0-9;]+m  \xE2\x9C\x95  \e\[0m/g), 2, 'and two squares in red with a cross: the two it takes');
    like($frames[-1], qr/\e\[48;5;94[;m]/, 'the throne has a ground of its own');
    like($frames[-1], qr/\e\[48;5;58[;m]/, 'and so have the corners');
    like($frames[-1], qr/\xE2\x99\x9A/, 'and the king is a crown');
};

subtest 'when the game is over' => sub {
    my $game = Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 d');
    my ($frames, $t) = sitting([ 'enter', 'down', 'down', 'down', 'enter', 'u', 'q' ], human => 'both', game => $game);
    is($t->game->status, 'active', 'u at the end takes the winning move back');
    is($t->game->ply, 0, 'and the game is on again');

    ($frames, $t) = sitting([ 'enter', 'down', 'down', 'down', 'enter', 'n', 'q' ], human => 'both',
        game => Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 d'));
    is($t->game->position, '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', 'n at the end starts again from the set-up');
};

subtest 'before the game: which side, and how hard' => sub {
    my ($frames, $t) = sitting([ 'down', 'enter', 'down', 'enter', 'q' ], menu => 1);
    like($frames->[0], qr/Which side will you take\?/, 'the first question');
    like($frames->[0], qr/ > The attackers /, 'with the attackers marked to begin with');
    like($frames->[1], qr/ > The defenders /, 'down moves the mark');
    like($frames->[2], qr/How hard should the program play\?/, 'enter, and the second question');
    like($frames->[2], qr/ > Level 2 /, 'with level 2 marked to begin with');
    is($t->human, 'defenders', 'the side chosen');
    is($t->level, 3, 'and the level');
    is($t->game->ply, 1, 'and the program, which has the attackers, has made its first move');

    ($frames, $t) = sitting([ 'down', 'down', 'enter', 'q' ], menu => 1);
    is($t->human, 'both', 'two people are not asked how hard the program should play');
    unlike(join('', @$frames), qr/How hard/, 'at all');

    ($frames, $t) = sitting([ 'q' ], menu => 1);
    is($t->game->ply, 0, 'q at the first question leaves without a game');
    is(scalar(@$frames), 1, 'after one screen');

    ($frames, $t) = sitting([ 'up', 'enter', 'q' ], menu => 1, pause => 0, variant => { ply_cap => 40 });
    is($t->human, 'none', 'up from the top goes round to the bottom: neither');
};

subtest 'the end of the keys ends the sitting, and hands the keyboard back' => sub {
    my ($frames, $t, $status) = sitting([ 'enter' ], human => 'both');
    is($status, 0, 'start returns 0');
    is($t->raw, 0, 'and the terminal is no longer in the mode it reads single keys in');
};

done_testing();
