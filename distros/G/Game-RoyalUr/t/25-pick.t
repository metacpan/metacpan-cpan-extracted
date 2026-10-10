use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);

use Game::RoyalUr;
use Game::RoyalUr::Terminal;
my $T = 'Game::RoyalUr::Terminal';

# THE ARROW KEYS. A terminal is handed its keys from a list in place of a
# keyboard, and writes to a tied handle, so that what a person would press and
# what they would see are both plain data.
{
    package Local::Out;
    sub TIEHANDLE { my $text = ''; return bless \$text, shift }
    sub PRINT     { my $self = shift; $$self .= join '', @_; return 1 }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }

    package Local::In;
    sub TIEHANDLE { return bless [], shift }
    sub READLINE  { undef }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }
}

my %KEY = (
    up => "\e[A", down => "\e[B", right => "\e[C", left => "\e[D", backtab => "\e[Z",
    enter => "\n", tab => "\t", space => ' ',
);

# a terminal that takes its keys from a list; a key name, or a character
sub keyed {
    my ($keys, %with) = @_;
    my @chars = map { split //, exists $KEY{$_} ? $KEY{$_} : $_ } @$keys;
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In';
    my $written = tie *$out, 'Local::Out';
    my @slept;
    my $terminal = $T->new(
        in => $in, out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1, pace => 0,
        keysource => sub { shift @chars }, sleeper => sub { push @slept, $_[0] },
        seed => 'facade 46', first => 'light', mode => 'hotseat', %with,
    );
    return ($terminal, $written, \@slept, \@chars);
}

sub standing {
    my ($keys, $position, $roll, %with) = @_;
    my $rules = delete $with{rules};
    my $game = Game::RoyalUr->new(script => [ { roll => $roll }, { roll => 1 }, { roll => 1 } ], position => $position,
                                  (defined $rules ? (rules => $rules) : ()));
    return keyed($keys, game => $game, %with);
}

# five candidates on a roll of 1: the hand, and pieces on b1, a2, g2 and h1
my $FIVE = '4xx2/l2d2l1/1l2xx1l l 2 1 6 0';

subtest 'tab walks the candidates in the order the game lists them' => sub {
    my ($t) = standing([], $FIVE, 1);
    my @legal = map { $_->from } $t->game->legal;
    is("@legal", 'hand b1 a2 g2 h1', 'the hand, then the pieces by how far along they are');
    is(join(' ', map { ($t->candidates)[$_]->from } 0 .. 4), "@legal", 'the candidates ARE the legal moves, in that order');
    my @walk = map { $t->steer('tab') } 1 .. 5;
    is("@walk", '1 2 3 4 0', 'tab goes round them and comes back');
    is($t->steer('backtab'), 4, 'and backtab goes the other way');
};

subtest 'a digit goes straight to a candidate' => sub {
    my ($t) = standing([], $FIVE, 1);
    is($t->steer('3'), 2, 'the third');
    is($t->steer('5'), 4, 'the fifth');
    is($t->steer('6'), 4, 'a digit past the last does nothing');
    is($t->steer('7'), 4, 'nor the one after');
    is($t->steer('x'), 4, 'nor a key that means nothing');
};

# THE CURSOR WALKS THE BOARD. Left and right go through the candidates from the
# left of the board to the right; up and down from the top row to the bottom.
# The hand sits where the gap in its side's row is.
subtest 'the arrows follow the board' => sub {
    my ($t) = standing([], $FIVE, 1);
    $t->steer('3');
    is(($t->candidates)[ $t->steer('left') ]->from, 'a2', 'a2 is the leftmost: left of it there is nothing, and the cursor stays');
    my @across = ('a2');
    push @across, ($t->candidates)[ $t->steer('right') ]->from for 1 .. 5;
    is("@across", 'a2 b1 hand g2 h1 h1', 'rightward: b1, the hand in the gap, g2, h1, and it stops at the edge');

    $t->steer('3');
    is(($t->candidates)[ $t->steer('up') ]->from, 'a2', 'row 2 is the highest row with a candidate: up of a2 stays');
    my @downward = ('a2');
    push @downward, ($t->candidates)[ $t->steer('down') ]->from for 1 .. 5;
    is("@downward", 'a2 g2 b1 hand h1 h1', 'downward: the rest of row 2, then row 1 from the left');
};

# From every candidate to every other, by arrows alone, over positions reached
# by play. The list of candidates is the GAME's, not the picker's.
subtest 'every candidate can be reached from every other' => sub {
    for my $rules ('finkel', 'masters') {
        my ($positions, $pairs, @bad) = (0, 0);
        my ($t) = keyed([], seed => "pick $rules", rules => $rules, first => 'light');
        my $pick = 0;
        while ($positions < 300 && !$t->game->is_over) {
            my @legal = $t->game->legal;
            $positions++;
            for my $start (0 .. $#legal) {
                for my $axis ([ 'left', 'right' ], [ 'up', 'down' ]) {
                    my %seen;
                    $t->steer($start + 1);
                    $seen{ $t->steer($axis->[0]) }++ for 1 .. 8;
                    $seen{ $t->steer($axis->[1]) }++ for 1 .. 8;
                    $pairs += @legal;
                    push @bad, "$axis->[0]/$axis->[1] from $start reached " . scalar(keys %seen) . ' of ' . scalar(@legal)
                        unless keys %seen == @legal;
                }
            }
            $t->game->play($legal[ $pick++ % @legal ]);
        }
        is(scalar @bad, 0, "$rules: $positions positions, $pairs pairs, by left and right alone and by up and down alone")
            or diag(join "\n", @bad[0 .. ($#bad > 4 ? 4 : $#bad)]);
    }
};

subtest 'enter plays the move under the cursor' => sub {
    my ($t, $written, undef, $left) = standing([ 'right', 'right', 'enter' ], $FIVE, 1);
    my @legal = $t->game->legal;
    my $choice = $t->pick;
    is($choice, 'h1-g1', 'the cursor starts on the hand; two to the right of the hand is h1, and enter plays h1');
    my ($under) = grep { $_->from . '-' . $_->to eq $choice } @legal;
    is($under, $legal[4], 'which is the game\'s own fifth legal move, the very object');
    is(scalar @$left, 0, 'having read all three keys');

    ($t) = standing(['space'], $FIVE, 1);
    is($t->pick, 'hand-d1', 'space plays too, and with no arrow pressed it is the first candidate');
    ($t) = standing([ '4', 'enter' ], $FIVE, 1);
    is($t->pick, 'g2-h2', 'a digit and enter plays that one');
    ($t) = standing([ 'tab', 'tab', 'backtab', 'enter' ], $FIVE, 1);
    is($t->pick, 'b1-a1', 'tab, tab, back one, enter: the second');
};

# THE PREVIEW IS THE RESULT. What the picker draws under the cursor is the
# board the move makes: take the marks away and it is, cell for cell, the board
# drawn after the move has been played.
subtest 'what is shown under the cursor is what the move leaves' => sub {
    my $bare = sub { (my $text = join "\n", @{ $_[0] }) =~ s/[\[\]()<>_]/ /g; $text =~ s/ +$//mg; $text =~ s/  +/ /g; $text };
    for my $case ([ $FIVE, 1, undef ], [ $FIVE, 3, { safe_rosettes => 0 } ], [ '4xxdd/l2d2ll/4xx1l l 3 0 4 0', 2, 'masters' ]) {
        my ($position, $roll, $rules) = @$case;
        my ($probe) = standing([], $position, $roll, rules => $rules);
        for my $index (0 .. scalar($probe->candidates) - 1) {
            my ($t) = standing([], $position, $roll, rules => $rules);
            my $move = ($t->candidates)[$index];
            my $before = $bare->($t->board_lines($move));
            $t->game->play($move) or die 'the move was refused';
            is($before, $bare->($t->board_lines), 'roll ' . $roll . ', ' . $move->from . '-' . $move->to
                . ($move->captures ? ' (a capture)' : '') . ($move->home ? ' (home)' : ''));
        }
    }
};

subtest 'the screen while picking' => sub {
    my ($t, $written) = standing([ '3', 'enter' ], $FIVE, 1);
    $t->pick;
    like($$written, qr/\e\[H/, 'the screen is redrawn in place');
    like($$written, qr/1: a2-b2\e\[K/, 'the line under the board says the move under the cursor');
    like($$written, qr/arrows choose a piece  enter move it/, 'and the keys are listed');
    like($$written, qr/\| \[ \] \| \(O\) \|/, 'with the board as that move leaves it');
};

# ONE LEGAL MOVE IS STILL A MOVE THE PLAYER MAKES.
subtest 'a move with no alternative waits to be made' => sub {
    my ($t, $written) = standing([], '4xx2/8/4xx2 l 7 0 7 0', 3);
    is(scalar($t->candidates), 1, 'one move on offer');
    is($t->pick, undef, 'with no key pressed, nothing is chosen');
    is($t->game->ply, 0, 'and nothing has been played');
    like($$written, qr/3: hand-b1   enters the board/, 'though it has been shown');

    ($t) = standing(['enter'], '4xx2/8/4xx2 l 7 0 7 0', 3);
    is($t->pick, 'hand-b1', 'and enter makes it');
};

subtest 'leaving is asked twice' => sub {
    my ($t, $written) = standing([ 'q', 'right', 'q', 'q' ], $FIVE, 1);
    is($t->pick, 'quit', 'q, another key, q, q: it leaves on the second q running');
    like($$written, qr/Press q again to leave the game, or any other key to stay\./, 'having asked');
    ($t) = standing([ 'q', 'enter' ], $FIVE, 1);
    isnt($t->pick, 'quit', 'q and then enter does not leave');
};

subtest 'the other keys' => sub {
    is((standing(['u'], $FIVE, 1))[0]->pick, 'undo', 'u asks to take back');
    is((standing(['n'], $FIVE, 1))[0]->pick, 'new', 'n for a new game');
    is((standing(['r'], $FIVE, 1))[0]->pick, 'route', 'r for the route');
    my ($t, $written) = standing([ '?', 'x', 'enter' ], $FIVE, 1);
    is($t->pick, 'hand-d1', '? shows the help, any key leaves it, and the picker carries on');
    like($$written, qr/arrows, tab     walk the pieces that can move/, 'the help was shown');
    is((standing(["\x04"], $FIVE, 1))[0]->pick, undef, 'the end of the input is the end');
};

# 'facade 46': light rolls 2, then dark and light each roll nothing, then dark
# rolls 1.
subtest 'a whole sitting on the keys, and a lost turn held on the screen' => sub {
    my ($t, $written, $slept) = keyed([ 'enter', 'u', 'enter', 'q', 'q' ], pace => 0.5);
    is($t->start, 0, 'start returns 0');
    is($t->game->ply, 3, 'a move, taken back, and made again: three plies with the two lost turns');
    is(join(' ', map { defined $_->{move} ? $_->{move} : '-' } @{ $t->game->log }), 'hand-c1 - -', 'the log');
    like($$written, qr/Dark rolled nothing and lost the turn\./, 'the lost turn was shown');
    is(scalar(grep { $_ == 0.5 } @$slept), 4, 'and held for the pace each time: two lost turns, twice over');
    like($$written, qr/Taken back\./, 'the take-back was said');

    # A PICKER REDRAWS THE WHOLE SCREEN FOR EVERY KEY. What has happened must
    # come through every one of those redraws, on the terminal's own list and
    # in the last frame it drew.
    is_deeply($t->events, [
        'Light played 2: hand-c1.',
        'Dark rolled nothing and lost the turn.',
        'Light rolled nothing and lost the turn.',
        'Taken back.',
        'Light played 2: hand-c1.',
        'Dark rolled nothing and lost the turn.',
        'Light rolled nothing and lost the turn.',
    ], 'everything that happened is still on the list after a dozen redraws');
    my ($last_frame) = $$written =~ /.*\e\[H(.*?)\e\[J/s;
    like($last_frame, qr/Light played 2: hand-c1\./, 'and the last frame drawn still shows the move');
    like($last_frame, qr/Dark rolled nothing and lost the turn\..*Light rolled nothing and lost the turn\./s,
        'and both lost turns, under the board, while the picker waits for dark');
    is($t->game->side, 'dark', 'and u went back to light\'s choice, through both lost turns, before it was made again');

    my ($quick, undef, $none) = keyed([ 'enter', 'q', 'q' ], pace => 0);
    $quick->start;
    is(scalar @$none, 0, 'with a pace of 0 nothing waits');
};

subtest 'against the program on the keys' => sub {
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In';
    my $written = tie *$out, 'Local::Out';
    my ($t, @slept, $presses);
    $t = $T->new(
        in => $in, out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1,
        seed => 'facade 46', first => 'light', mode => 'bot', level => 1, pace => 0.25,
        sleeper   => sub { push @slept, $_[0] },
        keysource => sub { $presses++; return $t->game->is_over ? 'q' : "\n" },
    );
    my $slept = \@slept;
    is($t->start, 0, "enter until the game is over, then q: $presses keys");
    ok($t->game->is_over, 'play a whole game against level 1');
    like($$written, qr/(?:You|Dark) won, all 7 home to \d/, 'and the result is shown');
    like($$written, qr/n new game  u take back  q leave/, 'with the keys for what to do next');
    cmp_ok(scalar @$slept, '>', 20, 'the program\'s moves and the lost turns were each held: ' . scalar(@$slept) . ' times');
    like($$written, qr/Dark played \d: /, 'and the program\'s moves were said');
};

subtest 'picking off, the same terminal reads lines' => sub {
    my ($t, $written) = keyed([ 'enter' ], picking => 0, interactive => 0);
    is($t->start, 0, 'with picking off and no lines to read, start returns');
    like($$written, qr/^light \(2\)> /m, 'having shown a prompt and not a picker');
    unlike($$written, qr/arrows choose a piece/, 'with no keys listed');
    is($t->game->ply, 0, 'and the enter in the key list was never read');
};

done_testing();
