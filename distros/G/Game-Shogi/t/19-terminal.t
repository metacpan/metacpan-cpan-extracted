use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use charnames ();
use Game::Shogi;
use Game::Shogi::Engine;
use Game::Shogi::Terminal;
use Game::Shogi::Test::Handle;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = 'Game::Shogi::Terminal';
my $E = 'Game::Shogi::Engine';

# Written from the rule and not from Terminal's columns, so a renderer and a
# measurer sharing one mistake cannot agree: a CJK, kana or fullwidth character
# is two columns, an escape none, everything else one.
sub width {
    my ($s) = @_;
    $s =~ s/\e\[[0-9;]*m//g;
    my $w = 0;
    for my $c (split //, $s) {
        my $o = ord $c;
        $w += ($o >= 0x3041 && $o <= 0x30FF) ? 2
            : ($o >= 0x4E00 && $o <= 0x9FFF) ? 2
            : ($o >= 0xFF00 && $o <= 0xFF60) ? 2
            :                                  1;
    }
    return $w;
}

sub terminal {
    my (%o) = @_;
    my $out = Game::Shogi::Test::Handle->recorder;
    return ($T->new(out => $out->fh, colour => 0, rewind => 0, %o), $out);
}

sub keysource {
    my @chars;
    for my $k (@_) {
        push @chars,
            $k eq 'up'     ? ("\e", '[', 'A')
          : $k eq 'down'   ? ("\e", '[', 'B')
          : $k eq 'right'  ? ("\e", '[', 'C')
          : $k eq 'left'   ? ("\e", '[', 'D')
          : $k eq 'enter'  ? ("\r")
          : $k eq 'tab'    ? ("\t")
          : $k eq 'escape' ? ("\e")
          :                  split //, $k;
    }
    return sub { shift @chars };
}

# Tab walks the drawn order one step at a time, so N tabs reach the Nth.
sub tabs_to {
    my ($set, $want) = @_;
    my ($i) = grep { $set->[$_] eq $want } 0 .. $#$set;
    die "'$want' is not in the set (@$set)\n" unless defined $i;
    return ('tab') x $i;
}

sub picker {
    my ($game, $keys, %o) = @_;
    my ($t, $out) = terminal(game => $game, ascii => 1, picking => 1, keysource => keysource(@$keys), %o);
    return ($t, $out);
}

sub board_with {
    my (@put) = @_;
    my $b = $E->new(empty => 1);
    while (my ($sq, $token) = splice @put, 0, 2) { $b->put($E->square($sq), $token) }
    return $b;
}

subtest 'the pieces are the codepoints pinned, checked by name' => sub {
    my %want = (
        P => [ 0x6B69, '歩' ], L => [ 0x9999, '香' ], N => [ 0x6842, '桂' ],
        S => [ 0x9280, '銀' ], G => [ 0x91D1, '金' ], B => [ 0x89D2, '角' ],
        R => [ 0x98DB, '飛' ], K => [ 0x7389, '玉' ], k => [ 0x738B, '王' ],
        '+P' => [ 0x3068, 'と' ], '+L' => [ 0x674F, '杏' ], '+N' => [ 0x572D, '圭' ],
        '+S' => [ 0x5168, '全' ], '+B' => [ 0x99AC, '馬' ], '+R' => [ 0x9F8D, '龍' ],
    );
    is(charnames::viacode(0x3068), 'HIRAGANA LETTER TO', 'the tokin is the hiragana to, not the katakana');
    my ($t) = terminal();
    for my $token (sort keys %want) {
        my $b = board_with('5e', $token);
        my ($row) = grep { /e\z/ } $t->board_lines(position => $b);
        my ($mark, $glyph) = $row =~ /([ v])([^\x00-\x7F\x{30FB}])/;
        is(sprintf('%04X', ord $glyph), sprintf('%04X', $want{$token}[0]), "$token is U+" . sprintf('%04X', $want{$token}[0]));
        is($glyph, $want{$token}[1], "  which is $want{$token}[1]");
        is($mark, $token =~ /[a-z]/ ? 'v' : ' ', '  with the side mark');
    }
    my $w = board_with('5e', 'p');
    my ($row) = grep { /e\z/ } $t->board_lines(position => $w);
    like($row, qr/ v歩 /, , 'a White pawn is v and the same kanji');
};

subtest 'every row of the board is the same width, in every mode' => sub {
    my $g = Game::Shogi->new(sfen => 'lnsgkgsnl/1r5+B1/pppppp1pp/6p2/9/2P6/PP1PPPPP1/7R1/LNSGKGSNL w Bp 4');
    for my $ascii (0, 1) {
        for my $ranks (0, 1) {
            for my $colour (0, 1) {
                for my $flip (0, 1) {
                    for my $marks ([], [ cursor => '2h' ], [ from => '2h', spots => [qw(2a 2b 2c)], cursor => '2a' ], [ cursor => 'B*' ]) {
                        my ($t) = terminal(game => $g, ascii => $ascii, kanji_ranks => $ranks, colour => $colour);
                        my @l = $t->board_lines(flip => $flip, @$marks);
                        is(scalar @l, 12, 'a hand, the files, nine ranks and a hand') or next;
                        my %w = map { width($_) => 1 } @l[ 1 .. 10 ];
                        is(scalar keys %w, 1, "ascii $ascii, kanji ranks $ranks, colour $colour, flip $flip, marks " . ($marks->[0] // 'none') . ": one width")
                            or diag(join "\n", map { width($_) . " $_" } @l);
                        is(width($l[2]), $T->columns($l[2]), '  and the terminal measures it as the rule does');
                    }
                }
            }
        }
    }
};

subtest 'the start in ASCII is the SFEN tokens, White at the top' => sub {
    my ($t) = terminal(ascii => 1);
    my @l = $t->board_lines(position => $E->new);
    is($l[1], '   9   8   7   6   5   4   3   2   1   ', 'the files 9 to 1, each over its token');
    is($l[2], '   l   n   s   g   k   g   s   n   l  a', 'rank a, White');
    is($l[3], '   .   r   .   .   .   .   .   b   .  b', 'rank b: the rook on 8b, the bishop on 2b');
    is($l[9], '   .   B   .   .   .   .   .   R   .  h', 'rank h: the bishop on 8h, the rook on 2h');
    is($l[0], ' white  -', 'White\'s empty hand above');
    is($l[11], ' black  -', 'Black\'s below');
};

subtest 'the board turns over for White, and the hands with it' => sub {
    my ($t) = terminal(ascii => 1);
    my @l = $t->board_lines(position => $E->new, flip => 1);
    is($l[1], '   1   2   3   4   5   6   7   8   9   ', 'the files 1 to 9');
    is($l[2], '   L   N   S   G   K   G   S   N   L  i', 'rank i at the top, from 1i');
    is($l[0], ' black  -', 'Black\'s hand above');
    is($l[11], ' white  -', 'White\'s below');
};

subtest 'kanji ranks and kanji' => sub {
    my ($t) = terminal(kanji_ranks => 1);
    my @l = $t->board_lines(position => $E->new);
    like($l[2], qr/一\z/, 'rank a is 一');
    like($l[10], qr/九\z/, 'rank i is 九');
    is($l[10], '  香  桂  銀  金  玉  金  銀  桂  香  九', 'Black\'s back rank');
    is($l[2],  ' v香 v桂 v銀 v金 v王 v金 v銀 v桂 v香  一', 'White\'s, marked v, its king 王');
    my ($a) = terminal(kanji_ranks => 1, ascii => 1);
    like(($a->board_lines(position => $E->new))[2], qr/ a\z/, 'ASCII keeps the letters');
};

subtest 'both hands as counts, in R B G S N L P order' => sub {
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b RB2G2S2N2L9Prb2g2s2n2l9p 1');
    my ($t) = terminal();
    my @l = $t->board_lines(position => $b);
    is($l[11], ' black  飛 角 金2 銀2 桂2 香2 歩9 ', 'Black\'s hand');
    is($l[0],  ' white  飛 角 金2 銀2 桂2 香2 歩9 ', 'White\'s, the same pieces');
    my ($a) = terminal(ascii => 1);
    @l = $a->board_lines(position => $b);
    is($l[11], ' black  R B G2 S2 N2 L2 P9 ', 'ASCII: Black\'s letters upper case');
    is($l[0],  ' white  r b g2 s2 n2 l2 p9 ', '  and White\'s lower');
    my @m = $a->board_lines(position => $b, cursor => 'G*');
    is($m[11], ' black  R B[G2]S2 N2 L2 P9 ', 'the cursor on a kind in hand');
    is($m[0],  ' white  r b g2 s2 n2 l2 p9 ', '  and only in the hand of the side to move');
};

subtest 'colour tells the sides apart; without it, the v does' => sub {
    my $b = board_with('5e', '+P', '4e', 'p', '9a', 'k', '1i', 'K');
    $b->set_hand('b', 'G', 2);
    $b->set_hand('w', 'S', 1);
    {
        local $ENV{NO_COLOR} = '0';
        my ($t) = terminal(colour => 1);
        my @l = $t->board_lines(position => $b);
        unlike(join('', @l), qr/\e\[/, 'NO_COLOR=0 still means no colour');
        like((grep { /e\z/ } @l)[0], qr/ v歩 /, '  and White is marked v');
    }
    local $ENV{NO_COLOR};
    delete $ENV{NO_COLOR};
    my ($t) = terminal(colour => 1);
    my @l = $t->board_lines(position => $b);
    my ($row) = grep { /e\z/ } @l;
    like($row, qr/ \e\[1;31mと\e\[0m /, 'a Black piece is red, promoted or not');
    like($row, qr/ \e\[1;34m歩\e\[0m /, 'a White piece is blue');
    unlike(join('', @l), qr/v/, '  and nothing is marked v');
    like($l[11], qr/\e\[1;31m金\e\[0m2/, 'Black\'s hand in red');
    like($l[0], qr/\e\[1;34m銀\e\[0m/, 'White\'s in blue');
    my ($a) = terminal(colour => 1, ascii => 1);
    my ($arow) = grep { /e\z/ } $a->board_lines(position => $b);
    like($arow, qr/ \e\[1;31m\+P\e\[0m /, 'ASCII is coloured the same way');
    like($arow, qr/ \e\[1;34mp\e\[0m /, '  White too');
};

subtest 'the marks hug the piece, in the gaps and the spare columns' => sub {
    my $b = board_with('5e', 'R', '5c', 'p', '9a', 'k', '1i', 'K', '7c', 'g');
    my ($t) = terminal(ascii => 1);
    my @l = $t->board_lines(position => $b, from => '5e', spots => [qw(5c 5d)], cursor => '5d');
    is($l[4], '   .   .   g   .  xpx  .   .   .   .  c', 'a capture: x both sides');
    is($l[5], '   .   .   .   .  [*]  .   .   .   .  d', 'the cursor on an empty target');
    is($l[6], '   .   .   .   .  (R)  .   .   .   .  e', 'the held piece');
    my @c = $t->board_lines(position => $b, cursor => '1i');
    is($c[10], '   .   .   .   .   .   .   .   .  [K] i', 'a mark on the edge stays inside the row');
    my ($k) = terminal();
    my @kc = $k->board_lines(position => $b, cursor => '5e', from => '7c');
    is($kc[6], '  ・  ・  ・  ・ [飛] ・  ・  ・  ・  e', 'kanji: a Black piece, the bracket against it');
    is($kc[4], '  ・  ・(v金) ・ v歩  ・  ・  ・  ・  c', '  a White one, the v inside');
};

subtest 'the sets come from the legal moves: pieces and pieces in hand' => sub {
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b P 1');
    my ($t) = terminal();
    my $o = $t->origins($b, 0);
    is_deeply($o, [ '5i', 'P*' ], 'the king and the pawn in hand, board first');
    is(scalar @{ $t->targets($b, 'P*', 0) }, 71, 'a pawn drops on 71 squares: not rank a, not the other king');
    my $s = $E->new;
    is(scalar @{ $t->origins($s, 0) }, 17, 'the start: seventeen pieces have a move (not the bishop, not the knights)');
    ok(!grep({ $_ eq '8i' || $_ eq '2i' } @{ $t->origins($s, 0) }), 'the knights have no move');
    is_deeply([ $t->choices($E->new(sfen => '4k4/9/9/9/9/9/9/4P4/4K4 b - 1'), '5h', '5g') ], ['5h5g'], 'one move, one choice');
};

subtest 'the picker: a board move' => sub {
    my $g = Game::Shogi->new;
    my ($probe) = terminal();
    my @keys = (tabs_to($probe->origins($g->board, 0), '7g'), 'enter', 'enter');
    my ($t) = picker($g, \@keys);
    is($t->pick_move($g), '7g7f', '7g, then its only square');
};

subtest 'the picker: a drop' => sub {
    my $g = Game::Shogi->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b P 1');
    my ($probe) = terminal();
    my $b = $g->board;
    my @keys = (tabs_to($probe->origins($b, 0), 'P*'), 'enter', tabs_to($probe->targets($b, 'P*', 0), '5e'), 'enter');
    my ($t) = picker($g, \@keys);
    is($t->pick_move($g), 'P*5e', 'the pawn in hand, then 5e');
};

subtest 'the picker: a promotion asked both ways, and escape' => sub {
    my $sfen = '4k4/9/9/2P6/9/9/9/9/4K4 b - 1';
    my $g = Game::Shogi->new(sfen => $sfen);
    my ($probe) = terminal();
    my $b = $g->board;
    is_deeply([ sort $probe->choices($b, '7d', '7c') ], [ '7d7c', '7d7c+' ], 'into the zone: two moves');
    my @to = (tabs_to($probe->origins($b, 0), '7d'), 'enter');
    my ($t, $out) = picker($g, [ @to, 'enter', 'y' ]);
    is($t->pick_move($g), '7d7c+', 'y promotes');
    like($out->text, qr/promote\? y or n/, '  after asking');
    ($t) = picker($g, [ @to, 'enter', 'n' ]);
    is($t->pick_move($g), '7d7c', 'n does not');
    ($t) = picker($g, [ @to, 'enter', 'escape', 'escape', 'q' ]);
    is($t->pick_move($g), 'quit', 'escape leaves the prompt, escape puts the piece back, q quits');

    my $f = Game::Shogi->new(sfen => '4k4/2P6/9/9/9/9/9/9/4K4 b - 1');
    is_deeply([ $probe->choices($f->board, '7b', '7a') ], [ '7b7a+' ], 'a pawn to the last rank must promote');
    my ($u, $o2) = picker($f, [ tabs_to($probe->origins($f->board, 0), '7b'), 'enter', 'enter' ]);
    is($u->pick_move($f), '7b7a+', '  and is played promoted');
    unlike($o2->text, qr/promote\?/, '  without asking');
};

subtest 'the picker\'s other keys' => sub {
    my $g = Game::Shogi->new;
    for ([ u => 'undo' ], [ r => 'redo' ], [ d => 'declare' ], [ q => 'quit' ]) {
        my ($t) = picker($g, [ $_->[0] ]);
        is($t->pick_move($g), $_->[1], "$_->[0] is $_->[1]");
    }
    my ($t) = picker($g, []);
    is($t->pick_move($g), 'quit', 'the keys running out is a quit, not a hang');
};

subtest 'the picker draws the board, and start draws only the last one bare' => sub {
    my $g = Game::Shogi->new;
    my ($t, $out) = picker($g, [ 'enter', 'enter', 'q' ], level => 400, seed => 'x');
    is($t->start, 0, 'it played a move and left');
    is(scalar $g->moves, 2, '  the move and the bot\'s reply');
    my @lines = split /\n/, $out->text;
    my (@bare, @marked);
    for my $i (0 .. $#lines) {
        next unless $lines[$i] =~ /\A   9   8/;
        my $board = join "\n", @lines[ $i .. ($i + 10 > $#lines ? $#lines : $i + 10) ];
        $board =~ /[\[\(]/ ? push(@marked, $i) : push(@bare, $i);
    }
    cmp_ok(scalar @marked, '>', 0, 'the picker drew boards with the cursor on them');
    is(scalar @bare, 1, 'exactly one board has no cursor') or diag("bare at @bare");
    cmp_ok($bare[0] // -1, '>', $marked[-1] // 0, '  after the last picker frame');
};

subtest 'undo and redo through the picker' => sub {
    my $g = Game::Shogi->new;
    my ($t, $out) = picker($g, [ 'enter', 'enter', 'u', 'r', 'q' ], level => 400, seed => 'x');
    $t->start;
    like($out->text, qr/taken back/, 'u took the turn back');
    like($out->text, qr/played again/, 'r played it again');
    is(scalar $t->game->moves, 2, 'and the game is where it was');
    my ($n, $o2) = picker(Game::Shogi->new, [ 'u', 'q' ], level => 400);
    $n->start;
    like($o2->text, qr/nothing to take back/, 'with nothing to take back, it says so');
};

subtest 'a move the bot offers and the game refuses stops the game' => sub {
    no warnings 'redefine';
    local *Game::Shogi::Bot::choose = sub { '5e5d' };
    my $g = Game::Shogi->new(sfen => 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1');
    ok($g->play('5e5d'), 'the game refuses 5e5d') and $g = Game::Shogi->new(sfen => $g->start);
    my ($t, $out) = terminal(in => Game::Shogi::Test::Handle->reader('quit')->fh, game => $g, picking => 0);
    my $status = eval {
        local $SIG{ALRM} = sub { die "start did not return\n" };
        alarm 10;
        my $s = $t->start;
        alarm 0;
        $s;
    };
    alarm 0;
    is($@, '', 'start returned rather than spinning');
    like($out->text, qr/the bot offered a move the game refused: /, '  and said so');
};

subtest 'typed moves, the commands, and the statuses' => sub {
    my $in = Game::Shogi::Test::Handle->reader('7g7f', 'nonsense', 'legal', 'sfen', 'log', 'declare', 'quit');
    my ($t, $out) = terminal(in => $in->fh, picking => 0, level => 400, seed => 's');
    is($t->start, 0, 'a quit is status 0');
    my $text = $out->decoded;
    like($text, qr/the bot plays \S+ \(\S+, \S+\)/, 'the bot\'s move with its Hodges and Japanese');
    like($text, qr/no: that is not a move \(bad_move\)/, 'a refused line says why');
    like($text, qr/^black to move> \d+ moves: /m, 'legal');
    like($text, qr/1\. ▲７六歩 P-7f 2\. △/, 'log, numbered, Japanese and Hodges');
    like($text, qr/cannot_declare/, 'declare refused, with its reason');

    my $lost = Game::Shogi->new(sfen => 'k8/9/9/9/9/9/4g4/9/4K4 w g 1');
    my ($l, $lo) = terminal(in => Game::Shogi::Test::Handle->reader->fh, game => $lost, picking => 0, level => 400);
    is($l->start, 1, 'mated by the bot: status 1');
    like($lo->text, qr/you lost: checkmate/, '  and it says why');

    my $won = Game::Shogi->new(sfen => 'k8/9/9/9/9/9/4g4/9/4K4 w g 1');
    my ($w, $wo) = terminal(in => Game::Shogi::Test::Handle->reader->fh, game => $won, picking => 0, level => 400, side => 'w');
    my $in2 = Game::Shogi::Test::Handle->reader('G*5h');
    $w->in($in2->fh);
    is($w->start, 0, 'mating the bot: status 0');
    like($wo->text, qr/you won: checkmate/, '  you won');
};

subtest 'ASCII is ASCII all the way through, captions and log included' => sub {
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    my ($t, $out) = picker(Game::Shogi->new, [ 'enter', 'right', 'enter', 'enter', 'g', 'h', 'q' ], level => 400, seed => 'a');
    $t->start;
    my $text = $out->text;
    ok(length $text > 1000, 'a game was drawn');
    unlike($text, qr/[^\x00-\x7F]/, 'not one byte above 0x7F');
    is_deeply(\@warned, [], 'and no warning, wide character or other');
    my $in = Game::Shogi::Test::Handle->reader('7g7f', 'log', 'hint', 'quit');
    my ($u, $o2) = terminal(in => $in->fh, ascii => 1, picking => 0, level => 400);
    $u->start;
    unlike($o2->text, qr/[^\x00-\x7F]/, 'typed: the same');
    like($o2->text, qr/1\. P-7f 2\. /, '  the log in Hodges alone');
};

subtest 'no picker line wraps an 80-column terminal' => sub {
    my $g = Game::Shogi->new(sfen => 'lnsgkgsnl/1r5b1/pppppp1pp/6p2/9/2P6/PP1PPPPPP/1B5R1/LNSGKGSNL b - 3');
    my ($probe) = terminal();
    my $b = $g->board;
    my @keys = (tabs_to($probe->origins($b, 0), '8h'), 'enter', tabs_to($probe->targets($b, '8h', 0), '2b'), 'enter', 'escape', 'escape', 'q');
    my ($t, $out) = picker($g, \@keys, ascii => 0);
    is($t->pick_move($g), 'quit', 'the bishop held over 2b, the prompt, and back');
    my @lines = split /\n/, $out->decoded;
    cmp_ok(scalar @lines, '>', 40, 'several frames drawn');
    my @long = grep { width($_) > 79 } @lines;
    is_deeply(\@long, [], 'every line fits in 79 columns, the help lines included');
    ok((grep { /promote\? y or n/ } @lines), '  the prompt among them');
    ok((grep { / \? for the keys *\z/ } @lines), '  the first help line whole, not clipped');
    ok((grep { / escape to pick another *\z/ } @lines), '  the second too');
};

subtest 'the side is checked' => sub {
    ok(!eval { $T->new(side => 'x'); 1 }, 'a side that is not b or w is refused');
    like($@, qr/'b' or 'w'/, '  naming both');
};

subtest 'options' => sub {
    my $o = $T->options;
    is_deeply([ map { $_->{name} } @$o ], [qw(level side handicap kanji-ranks seed)], 'the launcher\'s list');
    is($o->[0]{max}, 3, 'level is 0 to the last rung');
    isnt($T->options, $o, 'a new list each time');
};

done_testing;
