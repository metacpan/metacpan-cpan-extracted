use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);

use Game::Senet;
use Game::Senet::Terminal;
my $T = 'Game::Senet::Terminal';

# THE ARROW KEYS, plan_game_senet/08. A terminal is handed its keys from a list
# in place of a keyboard, and writes to a tied handle, so what a person would
# press and what they would see are both plain data.
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
        seed => 'pick', first => 'light', mode => 'hotseat', %with,
    );
    return ($terminal, $written, \@slept, \@chars);
}

sub standing {
    my ($keys, $position, $script, %with) = @_;
    my $rules = delete $with{rules};
    my $game = Game::Senet->new(script => (ref $script ? $script : [ $script ]), position => $position,
                                (defined $rules ? (rules => $rules) : ()));
    return keyed($keys, game => $game, %with);
}

my $FIVE = '.l...l..l./..l......./.l.......d l 5';

subtest 'no house twice in legal, so the picker is one step' => sub {
    for my $set (qw(kendall skyruk)) {
        my ($positions, @bad) = (0);
        my $n = 0;
        while ($positions < 300) {
            my $game = Game::Senet->new(seed => "twice $set " . $n++, rules => $set);
            while (!$game->is_over && $positions < 300) {
                my @from = map { $_->from } $game->legal;
                my %count;
                $count{$_}++ for @from;
                push @bad, "@from" if grep { $_ > 1 } values %count;
                $positions++;
                $game->play(($game->legal)[ $positions % @from ]);
            }
        }
        is(scalar @bad, 0, "$set: $positions positions, and no house offers two moves");
    }
};

subtest 'tab walks the candidates in the order the game lists them' => sub {
    my ($t) = standing([], $FIVE, 1);
    my @legal = map { $_->from } $t->game->legal;
    is("@legal", '2 6 9 13 22', 'the game lists the five by house');
    my @walk = map { $t->steer('tab') } 1 .. 5;
    is("@walk", '1 2 3 4 0', 'tab goes round them in that order');
    is($t->steer('backtab'), 4, 'and backtab the other way');
    is($t->steer('3'), 2, 'a digit goes straight to one');
    is($t->steer('6'), 2, 'and a digit past the last does nothing');
};

subtest 'the arrows follow the board as it is drawn' => sub {
    my ($t) = standing([], $FIVE, 1);
    my $from = sub { ($t->candidates)[ $_[0] ]->from };
    my @across = ($from->(0));
    push @across, $from->($t->steer('right')) for 1 .. 5;
    is("@across", '2 22 6 13 9 9', 'rightward by column: 22 is drawn under 2, 13 sits seventh in the middle row');
    $t->steer('1');
    my @down = ($from->(0));
    push @down, $from->($t->steer('down')) for 1 .. 5;
    is("@down", '2 6 9 13 22 22', 'downward by row: the top row, the middle, the bottom');
    is($from->($t->steer('left')), 2, 'and left from 22 is 2, the same column, first in the column order');
};

subtest 'every candidate can be reached from every other' => sub {
    for my $set (qw(kendall skyruk)) {
        my ($positions, $pairs, @bad) = (0, 0);
        my $n = 0;
        while ($positions < 300) {
            my ($t) = keyed([], seed => "reach $set " . $n++, rules => $set);
            while (!$t->game->is_over && $positions < 300) {
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
                $t->game->play($legal[ $positions % @legal ]);
            }
        }
        is(scalar @bad, 0, "$set: $positions positions, by left and right alone and by up and down alone")
            or diag(join "\n", @bad[0 .. ($#bad > 4 ? 4 : $#bad)]);
    }
};

subtest 'enter plays the move under the cursor, the very object' => sub {
    my ($t, undef, undef, $left) = standing([ 'tab', 'tab', 'enter' ], $FIVE, 1);
    my @legal = $t->game->legal;
    my $choice = $t->pick;
    is($choice, '9-10', 'tab, tab, enter: the third, from 9');
    my $played = $t->game->play($choice);
    is($played, $legal[2], 'which is the game\'s own third legal move, compared as an object');
    is(scalar @$left, 0, 'having read every key');
    ($t) = standing([ 'space' ], $FIVE, 1);
    is($t->pick, '2-3', 'space plays too, and with no arrow it is the first');
};

subtest 'what is shown under the cursor is what the move leaves' => sub {
    my $bare = sub { (my $text = join "\n", @{ $_[0] }) =~ s/[\[\]()<>{}]/ /g; $text =~ s/ +$//mg; $text =~ s/  +/ /g; $text };
    for my $case (
        [ $FIVE, 1, undef, 'an ordinary move' ],
        [ 'l...d...../........../.......... l 5', 4, undef, 'a swap' ],
        [ 'd........./........../.....l.... l 5', 1, undef, 'kendall onto 27, which ends on 15' ],
        [ '........../.........d/.l.l.d.... l 5', 4, undef, 'a backward move' ],
        [ 'd........./........../.l.......l l 5', 1, undef, 'a bear off' ],
        [ 'd........./........../......l... l 5', 2, 'skyruk', 'out of the water' ],
    ) {
        my ($position, $roll, $rules, $what) = @$case;
        my ($probe) = standing([], $position, $roll, rules => $rules);
        for my $index (0 .. scalar($probe->candidates) - 1) {
            my ($t) = standing([], $position, $roll, rules => $rules);
            my $move = ($t->candidates)[$index];
            my $before = $bare->($t->board_lines($move));
            $t->game->play($move) or die 'the move was refused';
            is($before, $bare->($t->board_lines), "$what: " . $move->trace);
        }
    }
};

subtest 'a move with no alternative waits to be made' => sub {
    my ($t, $written) = standing([], 'd........./........../.......l.. l 5', 3);
    is(scalar($t->candidates), 1, 'one move on offer: 28 off on a 3');
    is($t->pick, undef, 'with no key pressed, nothing is chosen');
    is($t->game->ply, 0, 'and nothing has been played');
    like($$written, qr/3: 28-off   bears off/, 'though it has been shown');
    ($t) = standing(['enter'], 'd........./........../.......l.. l 5', 3);
    is($t->pick, '28-off', 'and enter makes it');
};

subtest 'a bound throw offers the piece on 26 alone' => sub {
    my ($t) = standing([ 'left', 'right', 'tab', 'up', 'enter' ], 'd........./........../.l..l..... l 5', [ 2, 3 ],
                       rules => 'skyruk');
    $t->game->play_or_die('25-26');
    is(join(' ', map { $_->from } $t->candidates), '26', 'one candidate, the piece on 26');
    is($t->pick, '26-29', 'and no key moves the cursor off it');
};

subtest 'leaving is asked twice' => sub {
    my ($t, $written) = standing([ 'q', 'right', 'q', 'q' ], $FIVE, 1);
    is($t->pick, 'quit', 'q, another key, q, q: it leaves on the second q running');
    like($$written, qr/Press q again to leave the game, or any other key to stay\./, 'having asked');
};

subtest 'a whole sitting on the keys, and the forfeits held on the screen' => sub {
    my $game = Game::Senet->new(seed => 'sitting 3', position => 'l........./........../.......d.. l 5');
    my ($t, $written, $slept) = keyed([ 'enter', 'u', 'enter', 'q', 'q' ], game => $game, pace => 0.5);
    is($t->start, 0, 'start returns 0');
    is(join(' ', map { defined $_->{move} ? $_->{move} : '-' } @{ $t->game->log }), '1-3 - -',
        'a move, taken back, and made again; then two forfeits');
    is_deeply($t->events, [
        'Light played 2: 1-3.',
        'Dark threw #### (a 5) and could not move: throws again.',
        'Dark threw |##| (a 2) and could not move.',
        'Taken back.',
        'Light played 2: 1-3.',
        'Dark threw #### (a 5) and could not move: throws again.',
        'Dark threw |##| (a 2) and could not move.',
    ], 'everything that happened is on the list after every redraw');
    is(scalar(grep { $_ == 0.5 } @$slept), 4, 'each forfeit held for the pace: two of them, twice over');
    my ($last_frame) = $$written =~ /.*\e\[H(.*?)\e\[J/s;
    like($last_frame, qr/Light played 2: 1-3\./, 'and the last frame drawn still shows the move');
    like($last_frame, qr/Dark threw #### \(a 5\) and could not move: throws again\..*Dark threw \|##\| \(a 2\) and could not move\./s,
        'and both forfeits under the board, while the picker waits for light');
    is($t->game->side, 'light', 'light to move');
};

subtest 'once the game is won, enter leaves and n starts again' => sub {
    my $won = 'd........./........../.........l l 5';
    for my $leave (qw(enter space q)) {
        my ($t, $written, undef, $left) = standing([ 'enter', $leave, 'n' ], $won, 1);
        my $game = $t->game;
        is($t->start, 0, "$leave: start returns, a win");
        ok($t->game == $game && $game->is_over, '  and the game on the screen is the one won');
        is(scalar @$left, 1, '  with the n after it never read');
        like($$written, qr/Light won/, '  and the win was said');
    }
    my ($t) = standing([ 'enter', 'n' ], $won, 1);
    my $game = $t->game;
    $t->start;
    ok($t->game != $game && !$t->game->is_over, 'n: a new game');
};

subtest 'against the program on the keys' => sub {
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In';
    my $written = tie *$out, 'Local::Out';
    my ($t, @slept, $presses);
    $t = $T->new(
        in => $in, out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1,
        seed => 'program', first => 'light', mode => 'bot', level => 1, pace => 0.25,
        sleeper   => sub { push @slept, $_[0] },
        keysource => sub { $presses++; return $t->game->is_over ? 'q' : "\n" },
    );
    my $status = $t->start;
    ok($t->game->is_over, "a whole game against level 1, on $presses keys");
    is($status, $t->game->result->winner eq 'light' ? 0 : 1, 'start answers 0 for a win and 1 for a loss');
    cmp_ok(scalar @slept, '>', 20, 'the program\'s moves and the forfeits were each held: ' . scalar(@slept));
    like($$written, qr/Dark played \d: /, 'and the program\'s moves were said');
};

done_testing();
