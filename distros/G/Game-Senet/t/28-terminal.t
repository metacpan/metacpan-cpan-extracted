use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);

use Game::Senet;
use Game::Senet::Terminal;
my $T = 'Game::Senet::Terminal';

# THE TERMINAL'S FRAMES, plan_game_senet/08. The handles are TIED, not opened
# on a string: a capture through an in-memory handle came back undecoded on
# one smoker, and a tied handle has no layers to disagree about.
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
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In', @_;
    my $written = tie *$out, 'Local::Out';
    return ($in, $out, $written);
}

sub standing {
    my ($game, %with) = @_;
    my ($in, $out) = handles();
    return $T->new(in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0,
                   pace => 0, mode => 'hotseat', game => $game, %with);
}

sub plain { (my $text = join "\n", @{ $_[0] }) =~ s/\e\[[0-9;]*m//g; return $text }

my $START = <<'FRAME';
     dark   home: none

     +------+------+------+------+------+------+------+------+------+------+
     |1     |2     |3     |4     |5     |6     |7     |8     |9     |10    |
     |  @   |  O   |  @   |  O   |  @   |  O   |  @   |  O   |  @   |  O   |>-.
     +------+------+------+------+------+------+------+------+------+------+  |
  .-<|20    |19    |18    |17    |16    |15 +  |14    |13    |12    |11    |<-'
  |  |      |      |      |      |      |      |      |      |      |      |
  |  +------+------+------+------+------+------+------+------+------+------+
  '->|21    |22    |23    |24    |25    |26 X  |27 ~  |28 III|29 II |30 I  |>off
     |      |      |      |      |      |      |      |      |      |      |
     +------+------+------+------+------+------+------+------+------+------+

     light  home: none
FRAME

subtest 'the start, in ASCII, as a literal frame' => sub {
    my $t = standing(Game::Senet->new(seed => 'frame'));
    is(plain($t->board_lines) . "\n", $START, 'five a side, the S and its turns, the signs of the marked houses');
};

subtest 'seven pieces run into the middle row, right to left' => sub {
    my $t = standing(Game::Senet->new(seed => 'frame', rules => Game::Senet::Variant->named('kendall', pieces => 7)));
    my @lines = split /\n/, plain($t->board_lines);
    is($lines[7], '  |  |      |      |      |      |      |      |  O   |  @   |  O   |  @   |',
        '14, 13, 12, 11 from the left: light on 14 and 12, dark on 13 and 11');
};

subtest 'the S, read back' => sub {
    my @lines = split /\n/, plain(standing(Game::Senet->new(seed => 'frame'))->board_lines);
    my @middle = $lines[6] =~ /\|(\d+)\s/g;
    is("@middle", '20 19 18 17 16 15 14 13 12 11', 'the middle row runs 20 to 11, left to right');
    like($lines[4], qr/\|>-\.\z/, 'the track leaves 10 at the right');
    like($lines[6], qr/\A  \.-<\|20 .*\|11    \|<-'\z/, 'comes into 11 at the right and leaves 20 at the left');
    like($lines[9], qr/\A  '->\|21 .*\|30 I  \|>off\z/, 'comes into 21 at the left and bears off from 30');
};

subtest 'a sign stays drawn under a piece' => sub {
    my $game = Game::Senet->new(script => [ 2 ], position => '........../....l...../.....ldlll l 5', rules => 'skyruk');
    my $text = plain(standing($game)->board_lines);
    like($text, qr/\|15 \+  \|/, '15 keeps its ankh with light on it');
    like($text, qr/\|26 X  \|27 ~  \|28 III\|29 II \|30 I  \|/, 'and 26 to 30 their signs with pieces on every one');
    like($text, qr/\|  O   \|  @   \|  O   \|  O   \|  O   \|/, 'the pieces stand on the line below');
};

subtest 'every mark at once, each its own frame' => sub {
    my $game = Game::Senet->new(script => [ 1, 4, 3 ], position => 'l...d..l../........../.......... l 5');
    $game->play_or_die('8-9');
    my ($swap) = grep { $_->trace eq '1>5x' } $game->legal;
    ok($swap, 'light holds a 4: 1>5 swaps with dark');
    my $t = standing($game);
    my @lines = split /\n/, plain($t->board_lines($swap));
    like($lines[4], qr/\A     \| \(@\)  \|/, 'the house left, where the swapped piece goes: ( )');
    like($lines[4], qr/\A     \| \(@\)  \|      \|      \|      \| <O>  \|/, 'the landing: < >');
    like($lines[4], qr/\| \{O\}  \|/, 'the last move of light: { }');
    my ($plain) = grep { $_->trace eq '9>13' } $game->legal;
    my @quiet = split /\n/, plain($t->board_lines($plain));
    like($quiet[4], qr/\| \[ \]  \|/, 'a house left empty: [ ]');
};

subtest 'a mark is painted whole, both brackets and the piece between' => sub {
    my $game = Game::Senet->new(script => [ 1, 4, 3 ], position => 'l...d..l../........../.......... l 5');
    $game->play_or_die('8-9');
    my ($swap) = grep { $_->trace eq '1>5x' } $game->legal;
    my ($off) = grep { $_->off } Game::Senet->new(script => [ 1 ], position => 'd........./........../.l.......l l 5')->legal;
    for my $unicode (0, 1) {
        my $t = standing($game, colour => 1, unicode => $unicode);
        my $text = join "\n", @{ $t->board_lines($swap) };
        for my $pair ([ '(', ')' ], [ '<', '>' ]) {
            my ($open, $close) = map { quotemeta } @$pair;
            like($text, qr/\e\[[0-9;]+m$open[^\e]$close\e\[0m/,
                ($unicode ? 'unicode' : 'ascii') . ": $pair->[0]$pair->[1] in one span, no reset before the closing bracket");
        }
        unlike($text, qr/\e\[0m[)>\]]/, '  and no bracket of a mark follows a reset');
        my $home = standing(Game::Senet->new(script => [ 1 ], position => 'd........./........../.l.......l l 5'),
                            colour => 1, unicode => $unicode);
        my $lines = join "\n", @{ $home->board_lines($off) };
        like($lines, qr/\e\[[0-9;]+m<[^\e]>\e\[0m/, '  the piece borne off in the home row too');
    }
};

subtest 'colour stripped equals unpainted' => sub {
    my $game = Game::Senet->new(seed => 'colour');
    $game->play(($game->legal)[0]) for 1 .. 6;
    for my $unicode (0, 1) {
        my $painted = standing($game, colour => 1, unicode => $unicode);
        my $bare    = standing($game, colour => 0, unicode => $unicode);
        my $p = join "\n", @{ $painted->screen('plain') };
        my $b = join "\n", @{ $bare->screen('plain') };
        isnt($p, $b, ($unicode ? 'unicode' : 'ascii') . ': colour changes the bytes');
        (my $stripped = $p) =~ s/\e\[[0-9;]*m//g;
        is($stripped, $b, '  and stripped of it, the frame is the same character for character');
    }
};

subtest 'the sticks and the words, every throw, both glyph sets' => sub {
    my @want = (
        [ [0, 0, 0, 0], 5, '[ # # # # ]', 'no light face: a roll of 5, and throws again' ],
        [ [1, 0, 0, 0], 1, '[ | # # # ]', 'a roll of 1, and throws again' ],
        [ [1, 1, 0, 0], 2, '[ | | # # ]', 'a roll of 2' ],
        [ [1, 1, 1, 0], 3, '[ | | | # ]', 'a roll of 3' ],
        [ [1, 1, 1, 1], 4, '[ | | | | ]', 'a roll of 4, and throws again' ],
    );
    my $t = standing(Game::Senet->new(seed => 'sticks'));
    my $u = standing(Game::Senet->new(seed => 'sticks'), unicode => 1);
    for my $row (@want) {
        my ($sticks, $roll, $drawn, $words) = @$row;
        is($t->sticks_text($sticks), $drawn, "throw " . (grep { $_ } @$sticks) . ": $drawn");
        is($t->roll_words($roll, $roll =~ /[145]/), $words, "  $words");
        my $wide = $u->sticks_text($sticks);
        is(scalar(() = $wide =~ /\x{25AF}/g), scalar(grep { $_ } @$sticks), '  in unicode, a light face is its own glyph');
    }
    is($t->roll_words(3, 0, 26), 'a roll of 3, for the piece on 26', 'a bound throw says whose it is');
};

subtest 'a forfeit is said, kept on the screen, and the panel is four lines at most' => sub {
    my $game = Game::Senet->new(script => [ 1, 2, 3, 2, 2 ], position => 'd........./........../.......l.. l 5');
    is(scalar $game->forfeits_since(0), 2, 'light on 28 forfeited a 1 and a 2 before anything was asked');
    my $t = standing($game);
    $t->command('1-4');
    my @said = @{ $t->events };
    like($said[0], qr/\ADark played 3: 1-4\.\z/, 'dark\'s move is told');
    like($said[1], qr/\ALight threw a 2 and could not move\.\z/,
        'and light\'s forfeit after it, with its sticks: ' . ($said[1] // ''));
    like(plain($t->screen('plain')), qr/Light threw a 2 and could not move/, 'it is on the screen');
    $t->command('4-6');
    like(plain($t->screen('plain')), qr/Light threw a 2 and could not move/, 'and still there after the next move');
    $t->_event(undef, "line $_") for 1 .. 9;
    my @panel = grep { /line \d/ } split /\n/, plain($t->screen('plain'));
    is(scalar @panel, 4, 'with nine more things said, the panel shows the last four');
    like($panel[-1], qr/line 9/, '  ending with the newest');
};

subtest 'no line is wider than 80 columns' => sub {
    my $widest = 0;
    for my $unicode (0, 1) {
        for my $pieces (5, 7) {
            my $game = Game::Senet->new(seed => "wide $pieces", rules => Game::Senet::Variant->named('skyruk', pieces => $pieces));
            my $n = 0;
            while (!$game->is_over && $n++ < 400) {
                my $t = standing($game, unicode => $unicode);
                for my $mode (qw(plain pick wait)) {
                    for my $line (split /\n/, plain($t->screen($mode))) {
                        $widest = length $line if length $line > $widest;
                    }
                }
                $game->play(($game->legal)[ $n % scalar($game->legal) ]);
            }
        }
    }
    cmp_ok($widest, '<=', 80, "the widest line of every frame drawn, both glyph sets, five and seven pieces: $widest");
};

subtest 'ascii means ascii' => sub {
    my $game = Game::Senet->new(seed => 'ascii');
    $game->play(($game->legal)[0]) for 1 .. 10;
    my $text = plain(standing($game, unicode => 0)->screen('pick'));
    is(scalar(() = $text =~ /[^\x00-\x7f]/g), 0, 'not one character outside ASCII');
    my $wide = plain(standing($game, unicode => 1)->screen('pick'));
    cmp_ok(scalar(() = $wide =~ /[^\x00-\x7f]/g), '>', 0, 'and in unicode there are some');
};

done_testing();
