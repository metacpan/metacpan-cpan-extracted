use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Bot;
use Game::Xiangqi::Terminal;
use Game::Xiangqi::Test::Handle;

my $T = 'Game::Xiangqi::Terminal';

# THE WIDTH FUNCTION IS DUPLICATED HERE ON PURPOSE, and that is the whole point of
# the assertion below.
#
# Terminal.pm builds every row out of fixed-width cells and never measures a string
# to decide how to pad it. If this test called Terminal's own width function, a
# renderer and a measurer that share one function would agree with each other even
# when both were wrong, which is `index_tests_that_lie`'s "a probe that shares the
# bug". So the arithmetic is written twice, from the rule rather than from the code:
# a CJK or fullwidth character is two columns, everything else is one, and ANSI
# escapes are none.
sub width {
    my ($s) = @_;
    $s =~ s/\e\[[0-9;]*m//g;
    my $w = 0;
    for my $c (split //, $s) {
        my $o = ord $c;
        $w += ($o >= 0x1100 && $o <= 0x115F)        ? 2     # hangul jamo
            : ($o >= 0x2E80 && $o <= 0x303E)        ? 2     # CJK radicals, punctuation
            : ($o >= 0x3041 && $o <= 0x33FF)        ? 2     # kana, CJK compatibility
            : ($o >= 0x3400 && $o <= 0x4DBF)        ? 2     # extension A
            : ($o >= 0x4E00 && $o <= 0x9FFF)        ? 2     # the pieces live here
            : ($o >= 0xF900 && $o <= 0xFAFF)        ? 2     # compatibility ideographs
            : ($o >= 0xFF00 && $o <= 0xFF60)        ? 2     # fullwidth forms
            : ($o >= 0xFFE0 && $o <= 0xFFE6)        ? 2
            :                                         1;
    }
    return $w;
}

subtest 'the fourteen glyphs are the codepoints phase 01 pinned' => sub {
    # BY NUMBER, NEVER BY GLYPH. Phase 01 lost an hour to U+5E05 standing in for
    # U+5E25, and this file's first draft shipped U+4EF5 for the advisor and U+50CC
    # for the horse: the board it drew was perfectly legible and wrong, because a
    # glyph in a diff is exactly the check that does not work.
    my %want = (
        (RED   | GENERAL)  => 0x5E25, (BLACK | GENERAL)  => 0x5C07,
        (RED   | ADVISOR)  => 0x4ED5, (BLACK | ADVISOR)  => 0x58EB,
        (RED   | ELEPHANT) => 0x76F8, (BLACK | ELEPHANT) => 0x8C61,
        (RED   | CHARIOT)  => 0x4FE5, (BLACK | CHARIOT)  => 0x8ECA,
        (RED   | HORSE)    => 0x508C, (BLACK | HORSE)    => 0x99AC,
        (RED   | CANNON)   => 0x70AE, (BLACK | CANNON)   => 0x7832,
        (RED   | SOLDIER)  => 0x5175, (BLACK | SOLDIER)  => 0x5352,
    );

    my $t = $T->new(colour => 0);
    for my $piece (sort { $a <=> $b } keys %want) {
        my $pos = Game::Xiangqi::Engine->new(empty => 1);
        $pos->put(Game::Xiangqi::Engine->point_of(0, 0), $piece);
        my ($line) = grep { /\A0 / } $t->board_lines(position => $pos);
        # 2 columns of rank label and then the LEFT MARGIN, which is the column a
        # cursor bracket goes in when the cursor is on file a.
        my $glyph = (split //, substr $line, 3)[0];
        is(sprintf('U+%04X', ord $glyph), sprintf('U+%04X', $want{$piece}),
           sprintf 'piece %d draws U+%04X', $piece, $want{$piece});
    }

    # AND THE TWO SIDES DO NOT SHARE ONE, which is the opposite of chess and the
    # thing a chess programmer gets wrong here.
    my %seen;
    $seen{$_}++ for values %want;
    is(scalar keys %seen, 14, 'fourteen distinct characters, not seven');
};

subtest 'every row of the board is the same number of display columns' => sub {
    # 9 points at 2 columns and 8 gaps at 1 is 26, plus a 2-column rank label and a
    # 1-column margin at each side is 30. A board drawn as if a CJK glyph were one
    # column is skewed by one column per file and nine by the right-hand edge, and
    # it still looks like a board.
    #
    # THE MARGINS ARE WHAT MAKES A MARK FREE. A cursor bracket replaces the gap
    # character beside the point it is on, and files a and i have no gap on their
    # outer side, so without a margin the bracket on either edge would add a column
    # to one row out of twenty and skew the whole board by one.
    for my $mode ([ 'characters', {} ], [ 'ascii', { ascii => 1 } ],
                  [ 'coloured', { colour => 1 } ]) {
        my ($name, $opt) = @$mode;
        my $t = $T->new(%$opt, colour => $opt->{colour});
        my $E = 'Game::Xiangqi::Engine';

        # Every mark the picker can draw, including both edge files, and the three
        # of them at once, which is what a destination phase actually looks like.
        my @marked = (
            [ 'bare',        {} ],
            [ 'cursor on a', { cursor => $E->point_of(0, 0) } ],
            [ 'cursor on i', { cursor => $E->point_of(8, 9) } ],
            [ 'held and to', { from   => $E->point_of(0, 0),
                               cursor => $E->point_of(0, 3),
                               spots  => [ map { $E->point_of(0, $_) } 1 .. 4 ] } ],
            [ 'a capture',   { from   => $E->point_of(0, 0),
                               cursor => $E->point_of(0, 9),
                               spots  => [ $E->point_of(0, 9), $E->point_of(8, 9) ] } ],
        );

        for my $case (@marked) {
            my ($what, $o) = @$case;
            my @lines = $t->board_lines(%$o);
            is(scalar @lines, 20, "$name/$what: ten ranks, nine gaps and a legend");

            my %widths;
            $widths{ width($_) }++ for @lines;
            is(scalar keys %widths, 1,
               "$name/$what: one width across all 20 rows ("
               . join(', ', sort keys %widths) . ')')
                or diag(join "\n", map { sprintf '%3d |%s|', width($_), $_ } @lines);
            is((keys %widths)[0], 30, "$name/$what: and it is 30 columns");
        }
    }
};

subtest 'the view flips for the second seat, and the file letters do not' => sub {
    my @up   = $T->new(colour => 0)->board_lines;
    my @down = $T->new(colour => 0)->board_lines(flip => 1);

    like($up[0],   qr/\A9 /, 'unflipped starts at rank 9');
    like($down[0], qr/\A0 /, 'flipped starts at rank 0');

    # THE LEGEND IS ICCS's AND DOES NOT FLIP. A move is logged h2e2 whichever way
    # up the board is drawn, so a legend that flipped would make the log unreadable
    # to the person reading the screen.
    is($up[-1], $down[-1], 'the file letters are the same either way up');
    like($up[-1], qr/a .*b .*c .*d .*e .*f .*g .*h .*i/, '  and run a to i');
};

subtest 'NO_COLOR beats an explicit request for colour' => sub {
    {
        local $ENV{NO_COLOR} = '1';
        is($T->new(colour => 1)->colour, 0, 'NO_COLOR=1 wins over colour => 1');
    }
    {
        # THE PRESENCE IS WHAT COUNTS, NOT THE VALUE. no-color.org says so, and a
        # check written as `if ($ENV{NO_COLOR})` gets NO_COLOR=0 exactly backwards.
        local $ENV{NO_COLOR} = '0';
        is($T->new(colour => 1)->colour, 0, 'and so does NO_COLOR=0');
        is($T->new->colour, 0, '  with no request either way');
    }
    {
        local %ENV = %ENV;
        delete $ENV{NO_COLOR};
        is($T->new(colour => 1)->colour, 1, 'without it, colour => 1 is honoured');
        is($T->new(colour => 0)->colour, 0, '  and colour => 0 is too');
        like(join('', $T->new(colour => 1)->board_lines), qr/\e\[/, 'colour emits escapes');
        unlike(join('', $T->new(colour => 0)->board_lines), qr/\e\[/, 'and off emits none');
    }
};

subtest 'ascii is the seven FEN letters, uppercase for Red' => sub {
    my @lines = $T->new(ascii => 1)->board_lines;
    my $board = join "\n", @lines;
    unlike($board, qr/[^\x00-\x7F]/, 'nothing outside ASCII anywhere in it');
    like($lines[0],  qr/r.*h.*e.*a.*k.*a.*e.*h.*r/, 'rank 9 is black, lowercase');
    like($lines[18], qr/R.*H.*E.*A.*K.*A.*E.*H.*R/, 'rank 0 is red, uppercase');
};

subtest 'a game played through a pair of handles' => sub {
    my $in  = Game::Xiangqi::Test::Handle->reader(
        'board', 'legal', 'fen', 'log', 'help',
        'zz99',                       # refused, and named
        'h2e2',                       # a real move
        'log',
        'quit',
    );
    my $out = Game::Xiangqi::Test::Handle->recorder;

    my $g = Game::Xiangqi->new(seed => substr('terminal-test' . ('.' x 32), 0, 32), red => 'p1');
    my $t = $T->new(in => $in->fh, out => $out->fh, game => $g,
                    colour => 0, level => 400, seat => 'p1');
    my $status = $t->start;

    my $text = $out->text;
    is($status, 0, 'quitting is not a loss, so the status is 0');
    like($text, qr/44 moves/,      'legal listed all 44');
    like($text, qr{rnbakabnr|rheakaehr}, 'fen printed a FEN');
    like($text, qr/a move is ICCS/, 'help printed the help');
    like($text, qr/that is not a move \(bad_move\)/, 'the refusal named its flag');
    like($text, qr/h2e2/,          'and the move was played');
    is(scalar @{ $g->log } >= 1 ? 1 : 0, 1, 'the game has moves in it');
};

subtest 'start returns a status and never exits' => sub {
    # A module that calls exit cannot be tested and cannot be embedded. If `start`
    # ever exits, this test file stops here and the ones after it never run, which
    # is why the assertion is followed by another test rather than being the last.
    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $t = $T->new(in => Game::Xiangqi::Test::Handle->reader('quit')->fh,
                    out => $out->fh, colour => 0, level => 400);
    my $status = $t->start;
    ok(defined $status, 'it returned');
    is($status, 0, '  with a status');
};

subtest 'a lost game is status 1' => sub {
    # A position where Red is mated already, so the facade settles it on the first
    # look and the Terminal has a finished game to report.
    my $E = 'Game::Xiangqi::Engine';
    my $pos = $E->new(empty => 1);
    $pos->put($E->point_of(4, 0), RED | GENERAL);
    $pos->put($E->point_of(4, 9), BLACK | GENERAL);
    $pos->put($E->point_of(3, 1), BLACK | CHARIOT);
    $pos->put($E->point_of(5, 1), BLACK | CHARIOT);
    $pos->put($E->point_of(4, 2), BLACK | CHARIOT);
    $pos->set_side(RED);

    my $g = Game::Xiangqi->new(seed => 'x' x 32, red => 'p1', position => $pos);
    is(scalar @{ $g->legal }, 0, 'the fixture really does leave Red nothing');

    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $t = $T->new(in => Game::Xiangqi::Test::Handle->reader('quit')->fh,
                    out => $out->fh, game => $g, colour => 0, seat => 'p1');
    is($t->start, 1, 'the seat that lost gets status 1');
    like($out->text, qr/you lost/, '  and is told so');
};

my $E = 'Game::Xiangqi::Engine';

# ONE CHARACTER PER CALL, which is what Terminal's reader asks for and what makes
# an escape sequence testable: `read_sequence` has to ask three times for a single
# arrow key, and a source handing back whole keys would hide the pushback branch.
sub keysource {
    my @chars;
    for my $k (@_) {
        push @chars,
            $k eq 'up'     ? ("\e", '[', 'A')
          : $k eq 'down'   ? ("\e", '[', 'B')
          : $k eq 'right'  ? ("\e", '[', 'C')
          : $k eq 'left'   ? ("\e", '[', 'D')
          : $k eq 'home'   ? ("\e", '[', 'H')
          : $k eq 'end'    ? ("\e", '[', 'F')
          : $k eq 'enter'  ? ("\r")
          : $k eq 'tab'    ? ("\t")
          : $k eq 'escape' ? ("\e")
          :                  split //, $k;
    }
    return sub { shift @chars };
}

sub picker {
    my ($pos, @keys) = @_;
    my $g   = Game::Xiangqi->new(seed => 'p' x 32, red => 'p1',
                                 $pos ? (position => $pos) : ());
    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $t   = $T->new(out => $out->fh, game => $g, colour => 0, ascii => 1,
                      picking => 1, rewind => 0, keysource => keysource(@keys));
    return ($t, $g, $out);
}

subtest 'the cursor stops only where a move is, and never on a dead piece' => sub {
    my ($t, $g) = picker(undef);
    my $pos  = $g->position;
    my $from = $t->origins($pos);

    # THE SET IS THE ENGINE'S, NOT A SWEEP OF RED PIECES. From the opening Red has
    # sixteen pieces and only ten of them can move: both advisors, both elephants
    # and the general are shut in, and so is one of the two chariots' files. A
    # cursor walking "every point with a red piece on it" would stop five times on
    # a piece with nothing to do.
    my %legal_from = map { $E->move_from($_) => 1 } $pos->legal;
    is_deeply([ sort { $a <=> $b } @$from ],
              [ sort { $a <=> $b } keys %legal_from ],
              'the origins are exactly the from-points of legal');

    # AND A PIECE THAT REALLY CANNOT MOVE IS REALLY ABSENT. In the opening every
    # one of Red's sixteen has something to do, so the opening alone cannot show
    # this: it takes a position where a piece is shut in. The black general on d9
    # keeps the two off one file, which the first draft of this fixture forgot, and
    # a facing pair leaves Red two legal moves out of a board full of pieces.
    my $shut = $E->new(empty => 1);
    $shut->put($E->point_of(4, 0), RED | GENERAL);
    $shut->put($E->point_of(3, 9), BLACK | GENERAL);
    $shut->put($E->point_of(0, 0), RED | CHARIOT);
    $shut->put($E->point_of(0, 1), RED | SOLDIER);
    $shut->put($E->point_of(1, 0), RED | HORSE);
    $shut->set_side(RED);

    my %open = map { $_ => 1 } @{ $t->origins($shut) };
    ok(!$open{ $E->point_of(0, 0) },
       'a chariot boxed in by its own soldier and horse is not an origin');
    ok($open{ $E->point_of(0, 1) },  '  while the soldier in front of it is');
    ok($open{ $E->point_of(1, 0) },  '  and so is the horse');

    # And walking the whole ring in both directions never leaves the set.
    my %in = map { $_ => 1 } @$from;
    for my $key (qw(right left up down tab home end)) {
        my $at = 0;
        for (1 .. scalar(@$from) + 2) {
            $at = $t->step($from, $at, $key, 0);
            ok($in{ $from->[$at] }, "$key stayed on a point that has a move")
                or last;
        }
    }
};

subtest 'up and down change rank, and the flip turns them over' => sub {
    my ($t) = picker(undef);

    # A HAND-WRITTEN LIST, in the drawn order the picker sorts into: rank 9 first.
    # Nothing here comes from `origins`, so the walk is measured against the rule
    # and not against the code that implements it.
    my @pts = ($E->point_of(0, 9), $E->point_of(4, 9),
               $E->point_of(2, 5), $E->point_of(8, 5),
               $E->point_of(4, 0));

    is($t->step(\@pts, 0, 'down', 0), 2, 'down from a9 takes the nearer rank 5');
    is($t->step(\@pts, 1, 'down', 0), 2, '  and from e9 the closer file of the two');
    is($t->step(\@pts, 3, 'down', 0), 4, 'down from i5 reaches rank 0');

    # THE NEARER RANK FIRST AND THEN THE NEARER FILE: from e0 both c5 and i5 are
    # one row away, and c5 is two files off against i5's four.
    is($t->step(\@pts, 4, 'up',   0), 2, 'up from e0 takes the closer file of the two');

    # THE EDGES, WHICH IS WHERE A WALK THAT NEVER STOPS WOULD WRAP OR DIE. Rank 9
    # is the top row drawn and rank 0 the bottom, so up from one and down from the
    # other have nowhere to go and must stay put rather than wrap round.
    is($t->step(\@pts, 0, 'up',   0), 0, 'up from the top row stays');
    is($t->step(\@pts, 4, 'down', 0), 4, 'and down from the bottom row stays');

    # FLIPPED, rank 0 is drawn at the top, so the same keys go the other way.
    is($t->step(\@pts, 4, 'down', 1), 2, 'flipped, down from e0 goes to rank 5');
    is($t->step(\@pts, 4, 'up',   1), 4, '  and up from it has nowhere to go');
    is($t->step(\@pts, 0, 'up',   1), 2, 'flipped, up from a9 goes to rank 5');

    # left and right are the ring and do wrap, which is how tab behaves too.
    is($t->step(\@pts, 0, 'left',  0), 4, 'left from the first wraps to the last');
    is($t->step(\@pts, 4, 'right', 0), 0, 'and right from the last back to the first');
    is($t->step(\@pts, 2, 'home',  0), 0, 'home is the first');
    is($t->step(\@pts, 2, 'end',   0), 4, 'and end the last');
};

subtest 'the caption is the engine-s own vocabulary and not arithmetic' => sub {
    # Black is mated by Rd9: the general on e9 has d9 and f9 covered by the red
    # chariots already there, and e8 by the red cannon on e2.
    my $pos = $E->new(empty => 1);
    $pos->put($E->point_of(4, 9), BLACK | GENERAL);
    $pos->put($E->point_of(0, 8), RED | CHARIOT);
    $pos->put($E->point_of(3, 8), RED | CHARIOT);
    $pos->put($E->point_of(5, 8), RED | CHARIOT);
    $pos->put($E->point_of(0, 0), RED | GENERAL);
    $pos->set_side(RED);

    my ($t) = picker($pos->clone);
    my $mate = $pos->move($E->point_of(0, 8), $E->point_of(0, 9));
    ok($pos->is_mate($mate), 'the fixture really is a mate in one');
    like($t->move_line($pos, $mate), qr/\Aa9: a quiet move, and it is mate\z/,
         '  and the caption says so');

    # A capture NAMES THE PIECE IT TAKES, and the two sides do not share a name
    # any more than they share a glyph.
    #
    # THE GENERALS ARE KEPT OFF ONE FILE ON PURPOSE. Facing generals are a check
    # in this game, so a fixture that lines them up leaves the side to move two
    # legal moves whatever else is on the board, and every assertion about what a
    # chariot can reach measures the facing rule instead.
    my $prey = $E->new(empty => 1);
    $prey->put($E->point_of(0, 0), RED | CHARIOT);
    $prey->put($E->point_of(0, 5), BLACK | HORSE);
    $prey->put($E->point_of(4, 0), RED | GENERAL);
    $prey->put($E->point_of(3, 9), BLACK | GENERAL);
    $prey->set_side(RED);
    my $take = $prey->move($E->point_of(0, 0), $E->point_of(0, 5));
    like($t->move_line($prey, $take), qr/\Aa5: takes the black horse/,
         'a capture names its prey');

    like($t->piece_line($prey, $E->point_of(0, 0)),
         qr/\Athe red chariot on a0, \d+ moves\z/, 'and a piece names itself');
    like($t->piece_line($prey, $E->point_of(4, 0)),
         qr/\Athe red general on e0, \d+ moves?\z/, '  whichever piece it is');
};

subtest 'two phases: a piece, then a point, and escape puts it back' => sub {
    # home parks the cursor on the first origin in the drawn order, which is the
    # black side of the board for Red... no: origins are RED's, and rank 3 is the
    # highest rank a red piece with a move stands on, so the first is the soldier
    # on a3. Its only move is a3a4.
    my ($t, $g, $out) = picker(undef, 'home', 'enter', 'enter');
    my $chosen = $t->pick_move($g, 'p1');
    is($chosen, 'a3a4', 'the first origin is the a-file soldier and it plays a4');

    my $text = $out->text;
    like($text, qr/\( P\)/,  'the held piece is drawn in parentheses');
    like($text, qr/\[ \+\]/, '  and the point under the cursor in brackets');
    like($text, qr/a4: a quiet move/, 'the caption described the move');

    # ESCAPE GOES BACK TO CHOOSING A PIECE. Held, then escape, then enter on the
    # NEXT piece: the move that comes out must be the second piece's, which is the
    # proof the first was really let go.
    my ($t2, $g2) = picker(undef, 'home', 'enter', 'escape', 'right', 'enter', 'enter');
    my $second = $t2->pick_move($g2, 'p1');
    isnt($second, 'a3a4', 'escape let the first piece go');
    like($second, qr/\Ac3/, '  and the next origin is the c-file soldier');

    # q leaves from either phase.
    my ($t3, $g3) = picker(undef, 'q');
    is($t3->pick_move($g3, 'p1'), 'quit', 'q quits while choosing a piece');
    my ($t4, $g4) = picker(undef, 'enter', 'q');
    is($t4->pick_move($g4, 'p1'), 'quit', '  and while choosing a point');
};

subtest 'the picker draws the board, and start does not draw it again' => sub {
    # 0.03's first cut drew the board TWICE on every turn: `start` drew it after
    # the bot moved and `pick_move` drew it again with the cursor on it, so a
    # screen showed two boards one above the other and the top one was already
    # stale. The picker's first frame IS the board, so nothing else may draw one
    # while the picker is running.
    #
    # The assertion counts boards WITHOUT a cursor in them, which is the thing
    # that was wrong: every board the picker draws has a mark on it, and the only
    # bare one is the final position after the loop ends.
    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $g   = Game::Xiangqi->new(seed => 'd' x 32, red => 'p1');
    my $t   = $T->new(out => $out->fh, game => $g, colour => 0, ascii => 1,
                      picking => 1, rewind => 0, level => 400, seat => 'p1',
                      keysource => keysource('enter', 'enter', 'q'));
    is($t->start, 0, 'it played a move and left');
    is(scalar @{ $g->log }, 2, '  and the move and the bot-s reply were played');

    my @lines = split /\n/, $out->text;
    my (@bare, @marked);
    for my $i (0 .. $#lines) {
        next unless $lines[$i] =~ /\A9 /;
        my $board = join "\n", @lines[ $i .. ($i + 19 > $#lines ? $#lines : $i + 19) ];
        $board =~ /[\[\(]/ ? push(@marked, $i) : push(@bare, $i);
    }
    cmp_ok(scalar @marked, '>', 0, 'the picker drew boards with the cursor on them');
    is(scalar @bare, 1, 'and exactly one board has no cursor: the final position')
        or diag('bare boards at lines: ' . join ', ', @bare);
    cmp_ok($bare[0], '>', $marked[-1], '  which comes after the last picker frame');
};

subtest 'space does what enter does, in both phases' => sub {
    # A PICKER NOBODY HAS TO REACH FOR ENTER ON. Space is where the thumb already
    # is, and `read_key` hands a space back as itself rather than as a named key,
    # so it is a branch of its own and not something `enter` covers by accident.
    my ($t, $g) = picker(undef, 'home', ' ', ' ');
    is($t->pick_move($g, 'p1'), 'a3a4', 'space took the piece and played the point');

    # And the two really are interchangeable, not merely both present.
    my ($mixed, $g2) = picker(undef, 'home', ' ', 'enter');
    is($mixed->pick_move($g2, 'p1'), 'a3a4', 'space then enter reaches the same move');
    my ($other, $g3) = picker(undef, 'home', 'enter', ' ');
    is($other->pick_move($g3, 'p1'), 'a3a4', '  and so does enter then space');

    # AND THE LEGEND SAYS SO. A key that works and is not offered is a key nobody
    # presses.
    my ($said, $g4, $out) = picker(undef, 'q');
    $said->pick_move($g4, 'p1');
    like($out->text, qr/enter or space/, 'the line under the board offers both');
};

subtest 'a capture is marked on the board as a frame, not a colour' => sub {
    my $pos = $E->new(empty => 1);
    $pos->put($E->point_of(0, 0), RED | CHARIOT);
    $pos->put($E->point_of(0, 5), BLACK | HORSE);
    $pos->put($E->point_of(4, 0), RED | GENERAL);
    $pos->put($E->point_of(3, 9), BLACK | GENERAL);
    $pos->set_side(RED);

    # ASCII AND NO COLOUR AT ALL, which is the point: a mark that is a colour is
    # gone the moment somebody sets NO_COLOR or pipes the board into a file.
    #
    # An ascii cell is a space and then the letter, so a bracket round it reads
    # `[ P]` and not `[P]`: the mark replaces the GAP beside the point and never
    # a column of the point itself, which is what keeps the rows the same width.
    my $t = $T->new(colour => 0, ascii => 1);
    my $spots = $t->targets($pos, $E->point_of(0, 0));
    is(scalar @$spots, 8, 'the chariot on a0 has eight points to go to');

    my @lines = $t->board_lines(position => $pos, from => $E->point_of(0, 0),
                                cursor => $E->point_of(0, 4), spots => $spots);
    my $board = join "\n", @lines;
    unlike($board, qr/\e/, 'not one escape in it');
    like($board, qr/^5 x hx/m,    'the horse it can take is framed');
    like($board, qr/^4 \[ \+\]/m, 'the cursor is on an empty point it can reach');
    like($board, qr/^0 \( R\)/m,  'and the chariot it is holding is in parentheses');
    like($board, qr/^3   \+-/m,   'a reachable empty point is marked');
    like($board, qr/^9   \.-/m,   'and one it cannot reach is not');
};

subtest 'a move the bot offers and the game refuses stops the game' => sub {
    # 0.02 THREW THE REFUSAL AWAY. `choose` searches `legal`, so the facade should
    # never refuse what the bot offers and the ignored return looked harmless; but
    # the two agreeing is an assumption about two separate code paths, and when
    # they disagree the loop asks the same deterministic bot the same question for
    # ever, printing nothing. An unchecked return whose only failure mode is a hang
    # is worth the two lines.
    #
    # THE ALARM IS NOT DECORATION. Against the 0.02 code this subtest does not
    # fail, it HANGS, and a hanging assertion in a suite is worse than a missing
    # one: nobody reads it as red. The alarm turns the hang into a failure.
    my $slip = sub { return 'a0a9' };
    no warnings 'redefine';
    local *Game::Xiangqi::Bot::choose = $slip;

    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $g   = Game::Xiangqi->new(seed => 'b' x 32, red => 'p2');
    my $t   = $T->new(in => Game::Xiangqi::Test::Handle->reader('quit')->fh,
                      out => $out->fh, game => $g, colour => 0, picking => 0,
                      seat => 'p1');

    is($g->turn, 'p2', 'the bot is to move, so the bot branch runs first');
    ok($g->play('a0a9'), '  and a0a9 really is a move the game refuses');

    my $status = eval {
        local $SIG{ALRM} = sub { die "start did not return\n" };
        alarm 10;
        my $s = $t->start;
        alarm 0;
        $s;
    };
    alarm 0;
    is($@, '', 'start returned rather than spinning');
    ok(defined $status, '  with a status');
    like($out->text, qr/the bot offered a move the game refused/,
         '  and said what happened rather than going quiet');
};

subtest 'without a picker it still takes typed moves' => sub {
    my $in  = Game::Xiangqi::Test::Handle->reader('h2e2', 'quit');
    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $g   = Game::Xiangqi->new(seed => 't' x 32, red => 'p1');
    my $t   = $T->new(in => $in->fh, out => $out->fh, game => $g, colour => 0,
                      picking => 0, level => 400, seat => 'p1');
    is($t->start, 0, 'it played and quit');
    like($out->text, qr/a move is ICCS/, 'and said so rather than offering arrows');
    is($g->log->[0], 'h2e2', 'the typed move was played');
};

subtest 'in and out are read-write properties' => sub {
    my $t = $T->new(colour => 0);
    my $rec = Game::Xiangqi::Test::Handle->recorder;
    $t->out($rec->fh);
    is($t->out, $rec->fh, 'out took a new handle');
    $t->draw;
    like($rec->decoded, qr/\Q俥\E/, '  and the board went to it');

    my $rdr = Game::Xiangqi::Test::Handle->reader('quit');
    $t->in($rdr->fh);
    is($t->in, $rdr->fh, 'in took one too');
};

done_testing();
