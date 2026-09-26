use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
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
        my $glyph = (split //, substr $line, 2)[0];
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
    # 9 points at 2 columns and 8 gaps at 1 is 26, plus a 2-column rank label is 28.
    # A board drawn as if a CJK glyph were one column is skewed by one column per
    # file and nine by the right-hand edge, and it still looks like a board.
    for my $mode ([ 'characters', {} ], [ 'ascii', { ascii => 1 } ],
                  [ 'coloured', { colour => 1 } ]) {
        my ($name, $opt) = @$mode;
        my @lines = $T->new(%$opt, colour => $opt->{colour})->board_lines;
        is(scalar @lines, 20, "$name: ten ranks, nine gaps and a legend");

        my %widths;
        $widths{ width($_) }++ for @lines;
        is(scalar keys %widths, 1,
           "$name: one width across all 20 rows (" . join(', ', sort keys %widths) . ')')
            or diag(join "\n", map { sprintf '%3d |%s|', width($_), $_ } @lines);
        is((keys %widths)[0], 28, "$name: and it is 28 columns");
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
