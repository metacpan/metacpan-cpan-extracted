use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);
use File::Temp qw(tempdir);

use Game::RoyalUr;
use Game::RoyalUr::Terminal;
my $T = 'Game::RoyalUr::Terminal';

# THE TERMINAL, PLAYED BY TYPING. Lines go in on one handle and everything it
# says comes out on another, so a whole sitting is a list of lines in and a
# string out. Nothing here has a keyboard: the arrow keys are t/25's.
#
# The handles are TIED, not opened on a string: a capture through an in-memory
# handle came back undecoded on one smoker, and a tied handle has no layers to
# disagree about.
{
    package Local::Out;
    sub TIEHANDLE { my $text = ''; return bless \$text, shift }
    sub PRINT     { my $self = shift; $$self .= join '', @_; return 1 }
    sub PRINTF    { my $self = shift; $$self .= sprintf shift, @_; return 1 }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }
    sub CLOSE     { 1 }

    package Local::In;
    sub TIEHANDLE { my ($class, @lines) = @_; return bless [@lines], $class }
    sub READLINE  { my $self = shift; return @$self ? shift(@$self) . "\n" : undef }
    sub EOF       { !@{ $_[0] } }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }
    sub CLOSE     { 1 }
}

sub handles {
    my (@lines) = @_;
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In', @lines;
    my $written = tie *$out, 'Local::Out';
    return ($in, $out, $written);
}

# one sitting: the lines typed, and what was written
sub sitting {
    my ($lines, %with) = @_;
    my ($in, $out, $written) = handles(@$lines);
    my $terminal = $T->new(in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0,
                           pace => 0, seed => 'facade 46', first => 'light', %with);
    my $status = $terminal->start;
    return ($$written, $terminal, $status);
}

# a terminal standing on a position with a roll already decided
sub standing {
    my ($position, $roll, %with) = @_;
    my $rules = delete $with{rules};
    my $faces = delete $with{faces};
    my ($in, $out, $written) = handles();
    my $game = Game::RoyalUr->new(script => [ { roll => $roll, faces => $faces } ], position => $position,
                                  (defined $rules ? (rules => $rules) : ()));
    return $T->new(in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0,
                   pace => 0, mode => 'hotseat', game => $game, %with);
}

sub plain { (my $text = join "\n", @{ $_[0] }) =~ s/\e\[[0-9;]*m//g; return $text }

subtest 'a new terminal' => sub {
    my ($said, $t, $status) = sitting(['quit']);
    is($status, 0, 'start returns 0, and returns: it does not exit');
    like($said, qr/The Royal Game of Ur   finkel, you are light, against level 4/, 'it says what it is, the rules, and who you are');
    like($said, qr/^    dark   hand @ @ @ @ @ @ @   home none$/m, 'dark has seven in hand and none home');
    like($said, qr/^    light  hand O O O O O O O   home none$/m, 'and so has light');
    like($said, qr/^  3 \|\*    \|     \|     \|     \|           \|\*    \|     \|$/m, 'row 3, with its two rosettes and its gap');
    like($said, qr/^  2 \|     \|     \|     \|\*    \|     \|     \|     \|     \|$/m, 'row 2, with the middle rosette');
    like($said, qr/^  1 \|\*    \|     \|     \|     \|           \|\*    \|     \|$/m, 'row 1');
    like($said, qr/You rolled 2   \. \^ \^ \./, 'the roll, and the dice that made it');
    like($said, qr/^    1  2: hand-c1   enters the board$/m, 'the one move it allows, with its number');
    like($said, qr/^light \(2\)> /m, 'and a prompt that names the side and the roll');
    is($t->mode, 'bot', 'against the program unless told otherwise');
    is($t->side, 'light', 'as light');
    is($t->level, 4, 'at the top of the ladder');
};

subtest 'the end of the input ends the sitting' => sub {
    my ($said, $t, $status) = sitting([]);
    is($status, 0, 'no lines at all: start still returns 0');
    is($t->game->ply, 0, 'and nothing was played');
};

# 'facade 46' with light first rolls 2, then 0 and 0, then 1.
subtest 'a turn lost to the roll is said, and stays said' => sub {
    my ($said, $t) = sitting([ 'hand-c1', 'quit' ], mode => 'hotseat');
    is($t->game->ply, 3, 'one move typed, and two turns lost after it');
    like($said, qr/Light played 2: hand-c1\./, 'the move');
    like($said, qr/Dark rolled nothing and lost the turn\./, 'dark\'s lost turn');
    like($said, qr/Light rolled nothing and lost the turn\./, 'and light\'s');
    like($said, qr/Dark rolled 1   \. \. \. \^/, 'and then dark has a roll');
    like($said, qr/^  1 \|\*    \|     \| _O_ \|     \|/m, 'the piece that moved is marked where it landed');
    is_deeply($t->events, [
        'Light played 2: hand-c1.',
        'Dark rolled nothing and lost the turn.',
        'Light rolled nothing and lost the turn.',
    ], 'three things have happened, in order');
};

subtest 'the last four things that happened are always on the screen, and no more' => sub {
    my ($said, $t) = sitting([ 'hand-c1', '1', '1', '1', '1', '1', 'quit' ], mode => 'hotseat');
    my @events = @{ $t->events };
    cmp_ok(scalar @events, '>=', 7, scalar(@events) . ' things have happened');
    my $screen = plain($t->screen('plain'));
    like($screen, qr/\Q$events[$_]\E/, "the screen still shows: $events[$_]") for -4 .. -1;
    unlike($screen, qr/\Q$events[0]\E/, 'and no longer the first of them');
    is(scalar(grep { /played|rolled .* (?:lost|could not)/ } split /\n/, $screen), 4, 'four lines of it, not five');
};

subtest 'two people, typing moves' => sub {
    my ($said, $t) = sitting([ 'hand-c1', 'HAND-D3', '1', 'quit' ], mode => 'hotseat');
    is(join(' ', map { defined $_->{move} ? $_->{move} : '-' } @{ $t->game->log }), 'hand-c1 - - hand-d3 hand-d1',
        'a move, a move in capitals, and a number from the list');
    like($said, qr/The Royal Game of Ur   finkel, two players/, 'the title says two players');
    like($said, qr/^dark \(1\)> /m, 'and the prompt passes between them');
};

subtest 'a refusal says what was wrong, and nothing moves' => sub {
    my ($said, $t) = sitting([ 'a2-b2', 'hand-d1', 'hand-home', 'zz9', '9', '5', 'quit' ], mode => 'hotseat');
    is($t->game->ply, 0, 'six lines, and not one move');
    like($said, qr/You have no piece there\./, 'the empty square');
    like($said, qr/A piece moves exactly as far as the roll\./, 'the wrong distance');
    like($said, qr/I do not know 'zz9'\. A move is two places, like hand-b1 or a2-d2, or its number in the list\./, 'a line that is no move');
    like($said, qr/I do not know '9'\./, 'a number that is not one of seven');
    like($said, qr/There are only 1 moves to choose from\./, 'and a number past the end of the list');
};

subtest 'against the program' => sub {
    my ($said, $t) = sitting([ 'hand-c1', 'quit' ], level => 1);
    like($said, qr/You played 2: hand-c1\./, 'you are "you"');
    like($said, qr/Dark rolled nothing and lost the turn\./, 'the program lost a turn');
    like($said, qr/You rolled nothing and lost the turn\./, 'and so did you');
    like($said, qr/Dark played 1: hand-d3\./, 'and then the program moved by itself');
    like($said, qr/against level 1/, 'at the level asked for');

    ($said, $t) = sitting(['quit'], side => 'dark', level => 1);
    like($said, qr/Light played 2: hand-c1\./, 'as dark, the program has light and moves first');
    like($said, qr/you are dark/, 'and the title says who you are');
};

subtest 'the program against itself' => sub {
    my ($said, $t, $status) = sitting([], mode => 'watch', level => 1);
    ok($t->game->is_over, 'it plays to the end with nobody typing');
    like($said, qr/(?:Light|Dark) won, all 7 home to \d, in \d+ plies\./, 'and says who won and by how much');
    like($said, qr/level 1 against itself/, 'the title says what is playing');
    is($status, 0, 'and start returns');
};

# THREE MARKS, THREE SHAPES. A capture under the cursor: where the piece was,
# where it lands, and the piece it sends back.
subtest 'the board a move would leave' => sub {
    my $t = standing('4xx2/l2d2l1/1l2xx1l l 2 1 6 0', 3, rules => { safe_rosettes => 0 }, faces => '1011');
    my @moves = $t->candidates;
    is(join(' ', map { $_->from . '-' . $_->to } @moves), 'b1-b2 a2-d2 g2-g1', 'three moves on a roll of 3');
    my $after = join "\n", @{ $t->board_lines($moves[1]) };
    like($after, qr/^  2 \| \[ \] \|     \|     \|\*\(O\) \|     \|     \|  O  \|     \|$/m,
        'a2 is empty in [ ], and the piece stands on d2 in ( ) with the rosette still drawn beside it');
    like($after, qr/^    dark   hand @ @ @ @ @ @ <@>   home none$/m, 'the dark piece is back in dark\'s hand, in < >');
    like($after, qr/^    light  hand O O   home O$/m, 'and light\'s hand and home are as they were');

    my $enter = standing('4xx2/8/4xx2 l 7 0 7 0', 4);
    my $entered = join "\n", @{ $enter->board_lines(($enter->candidates)[0]) };
    like($entered, qr/^    light  hand O O O O O O \[ \]   home none$/m, 'a piece entering leaves an empty [ ] in the hand');
    like($entered, qr/^  1 \|\*\(O\) \|/m, 'and lands in ( ) on a1');

    my $home = standing('4xx2/8/4xxl1 l 3 3 7 0', 1);
    my $gone = join "\n", @{ $home->board_lines(($home->candidates)[1]) };
    like($gone, qr/^    light  hand O O O   home O O O \(O\)$/m, 'a piece going home arrives in ( ) at home');
    like($gone, qr/^  1 \|\*    \|     \|     \|     \|           \|\*\[ \] \|/m, 'leaving [ ] on g1');
};

subtest 'colour is on top of the marks, never instead of them' => sub {
    my $position = '4xx2/l2d2l1/1l2xx1l l 2 1 6 0';
    my $bare = standing($position, 3, rules => { safe_rosettes => 0 });
    my $painted = standing($position, 3, rules => { safe_rosettes => 0 }, colour => 1);
    for my $index (0 .. 2) {
        my $one = join "\n", @{ $bare->board_lines(($bare->candidates)[$index]) };
        my $two = $painted->board_lines(($painted->candidates)[$index]);
        like(join("\n", @$two), qr/\e\[/, "move $index: the painted board has colour in it");
        is(plain($two), $one, "move $index: and with the colour taken out it is the unpainted board, mark for mark");
    }
    is(plain($painted->screen('pick')), join("\n", @{ $bare->screen('pick') }), 'the whole screen likewise');
};

subtest 'the dice' => sub {
    my %want = ('1011' => '^ . ^ ^', '0001' => '. . . ^', '1111' => '^ ^ ^ ^', '0110' => '. ^ ^ .');
    for my $faces (sort keys %want) {
        my $roll = ($faces =~ tr/1//);
        my $t = standing('4xx2/8/4xx2 l 7 0 7 0', $roll, faces => $faces);
        like(plain($t->screen('plain')), qr/Light rolled $roll   \Q$want{$faces}\E$/m, "$faces is drawn as $want{$faces}");
    }
    my $masters = standing('4xx2/8/4xx2 l 7 0 7 0', 4, rules => 'masters', faces => '000');
    like(plain($masters->screen('plain')), qr/Light rolled 4   \. \. \.   \(nothing marked is worth four\)/,
        'under masters three unmarked dice are a 4, and the screen says why');
    my $three = standing('4xx2/8/4xx2 l 7 0 7 0', 2, rules => 'masters', faces => '101');
    like(plain($three->screen('plain')), qr/Light rolled 2   \^ \. \^$/m, 'and there are three of them');
};

subtest 'drawn with lines and shapes, or with letters' => sub {
    my $wide = standing('4xx2/3d4/1l2xx2 l 6 0 6 0', 2, unicode => 1, faces => '1100');
    my $screen = join "\n", @{ $wide->screen('plain') };
    like($screen, qr/\x{25CF}/, 'a light piece is a filled disc');
    like($screen, qr/\x{25CB}/, 'a dark piece is a ring: a different SHAPE');
    like($screen, qr/\x{2726}/, 'a rosette is a star');
    like($screen, qr/\x{2726} \x{25CB}  \x{2502}/, 'and it is still drawn beside the piece standing on it');
    like($screen, qr/\x{25B2} \x{25B2} \x{25B3} \x{25B3}/, 'marked and unmarked dice');
    like($screen, qr/\x{256D}\x{2500}{5}\x{252C}/, 'and the board has corners');

    my $letters = standing('4xx2/3d4/1l2xx2 l 6 0 6 0', 2, unicode => 0, faces => '1100');
    unlike(join("\n", @{ $letters->screen('plain') }), qr/[^\x00-\x7F]/, 'with unicode off there is not one character outside ASCII');
};

subtest 'the route' => sub {
    my $t = standing('4xx2/8/4xx2 l 7 0 7 0', 2, rules => 'masters');
    unlike(plain($t->screen('plain')), qr/route, as/, 'not shown unless asked');
    $t->command('route');
    my $screen = plain($t->screen('plain'));
    like($screen, qr/The long route, as light travels it:/, 'asked for, it is named');
    like($screen, qr/^    3     \.     \.     \.     \.                12    13  $/m, 'light visits g3 and h3 twelfth and thirteenth');
    like($screen, qr/^    2     5     6     7     8     9    10    11    14  $/m, 'the middle row fifth to eleventh, and its last square fourteenth');
    like($screen, qr/^    1     4     3     2     1                16    15  $/m, 'and its own row first and last');
    $t->command('route');
    unlike(plain($t->screen('plain')), qr/route, as/, 'and asked again it goes');
};

subtest 'the commands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/game.txt";
    my ($said, $t) = sitting([ 'hand-c1', 'moves', 'undo', 'undo', "record $file", 'record', 'level 2', 'level 9',
                               'help', 'new', 'quit' ], mode => 'hotseat');
    like($said, qr/^    2: hand-c1\n    0: -\n    0: -$/m, 'moves lists what has been played, lost turns and all');
    like($said, qr/Taken back\./, 'undo takes a move back');
    like($said, qr/There is nothing to take back\./, 'and says so when there is none');
    ok(-s $file, 'record writes a file');
    like($said, qr/The game is written to \Q$file\E\./, 'and says so');
    like($said, qr/record wants the name of a file\./, 'and wants a name');
    like($said, qr/The program now plays at level 2\./, 'level sets the level');
    like($said, qr/A level is a number from 1 to 4\./, 'within the ladder');
    like($said, qr/arrows, tab     walk the pieces that can move/, 'help lists the keys');
    is($t->game->ply, 0, 'and new is a new game');
    isnt($t->seed, 'facade 46', 'with a new seed');

    open my $fh, '<', $file or die "cannot read $file: $!";
    my $record = do { local $/; <$fh> };
    close $fh;
    like($record, qr/\A\[rules finkel\]\n\[first light\]\n\[seed [0-9a-f]+\]\n\z/, 'the file is a record of the game as it stood');
};

subtest 'who starts, when the dice decide' => sub {
    my ($said, $t) = sitting(['quit'], seed => 'facade 1', first => 'roll', mode => 'hotseat');
    like($said, qr/To see who starts, light threw \^ \. \^ \^ 3 and dark \^ \^ \. \^ 3: a tie, again\./, 'the tie is shown, dice and all');
    like($said, qr/To see who starts, light threw \. \. \. \. 0 and dark \. \. \. \^ 1\./, 'and the throw that settled it');
    like($said, qr/Dark moves first\./, 'and who it settled on');
    like($said, qr/^dark \(\d\)> /m, 'who is then asked to move');

    ($said) = sitting(['quit'], seed => 'facade 1', first => 'dark', mode => 'hotseat');
    unlike($said, qr/To see who starts/, 'told who starts, nothing is thrown for it');
};

subtest 'a game that is over' => sub {
    my $t = standing('4xx2/1d6/4xxl1 l 0 6 6 0', 1);
    $t->command('g1-home');
    my $screen = plain($t->screen('plain'));
    like($screen, qr/Light won, all 7 home to 0, in 1 plies\./, 'the result is on the screen');
    like($screen, qr/Light played 1: g1-home, home\./, 'with the move that did it');
    $t->command('hand-d1');
    like(plain($t->screen('plain')), qr/The game is over\. Type new, undo or quit\./, 'a move after the end is answered');
    ok(!$t->command('undo'), 'undo does not leave');
    ok(!$t->game->is_over, 'and the game is going again');
    ok($t->command('quit'), 'quit does');
};

subtest 'what new refuses' => sub {
    my @bad = ([ mode => 'solo' ], [ side => 'white' ], [ first => 'me' ], [ level => 9 ], [ level => 0 ],
               [ pace => 'fast' ], [ rules => 'bell' ]);
    for my $case (@bad) {
        my ($in, $out) = handles();
        ok(!eval { $T->new(in => $in, out => $out, interactive => 0, @$case); 1 }, "$case->[0] => '$case->[1]' croaks");
    }
};

done_testing();
