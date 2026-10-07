#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Backgammon;
use Game::Backgammon::Board ();
use Game::Backgammon::Terminal;

# Building a turn with the keys, driven through keysource rather than by a
# person: no terminal, no pty, and Term::ReadKey not needed to run any of it.

sub seed_of { Digest::SHA::sha256($_[0]) }

sub picker {
    my (%o) = @_;
    my @chars = split //, defined $o{keys} ? $o{keys} : '';
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $ui = Game::Backgammon::Terminal->new(
        game => $o{game} || Game::Backgammon->new(seed => seed_of($o{seed} || 'pick')),
        out => $fh,
        mode => $o{mode} || 'hotseat',
        ascii => 1,
        colour => defined $o{colour} ? $o{colour} : 0,
        interactive => 0,
        picking => 1,
        keysource => sub { shift @chars },
        ($o{view} ? (view => $o{view}) : ()),
    );
    $ui->_enter_raw;
    return ($ui, \$out);
}

# the position this leans on: a roll with a long list of legal turns, found
# rather than asserted, so the test is about the shape of the list and not
# about one lucky seed
sub crowded {
    for my $seed (1 .. 12) {
        my $game = Game::Backgammon->new(seed => seed_of("crowd-$seed"));
        for (1 .. 10) {
            last if $game->status ne 'active';
            my $turns = $game->legal_turns;
            return ($game, $turns) if @$turns >= 50;
            $game->play($turns->[ int(@$turns / 2) ]);
        }
    }
    return ();
}

subtest 'a key at a time, named' => sub {
    plan tests => 2;
    my ($ui) = picker(keys => "k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");
    my @got;
    while (defined(my $key = $ui->_read_key)) {
        push @got, $key eq ' ' ? 'space' : $key;
    }
    is_deeply(\@got, [qw/k up down right left page_up home enter tab backspace
        interrupt eof space q escape page_down/],
        'a character is itself and a sequence is a name');

    my ($escaped) = picker(keys => "\eq");
    is_deeply([$escaped->_read_key, $escaped->_read_key], ['escape', 'q'],
        'and an escape does not eat the keystroke behind it');
};

subtest 'a long list of turns becomes a few short ones' => sub {
    my ($game, $turns) = crowded();
    plan skip_all => 'no crowded roll found in twelve seeds' unless $game;
    plan tests => 4;

    cmp_ok(scalar @$turns, '>=', 50, 'the roll really is legal many ways');

    my ($ui) = picker(game => $game);
    my $first = $ui->_next_moves($turns, []);
    cmp_ok(scalar @$first, '<', scalar @$turns,
        'but the first choice is shorter than the list of turns');
    cmp_ok(scalar @$first, '<=', 12,
        'short enough to read without scrolling the board away');

    # and every step of it stays short, all the way to a finished turn
    my @chosen;
    my $widest = 0;
    while (1) {
        my $match = $ui->_matching($turns, \@chosen);
        my $next = $ui->_next_moves($match, \@chosen);
        last unless @$next;
        $widest = @$next if @$next > $widest;
        push @chosen, $next->[0];
    }
    cmp_ok($widest, '<=', 12, 'no step of the turn offers more than that');
};

subtest 'every path leads to a turn the rules offered' => sub {
    my ($game, $turns) = crowded();
    plan skip_all => 'no crowded roll found in twelve seeds' unless $game;
    plan tests => 3;

    my ($ui) = picker(game => $game);
    my %legal = map { $_->key => 1 } @$turns;

    # walk the choices every way round: first option each time, last option
    # each time, and the middle one. None of them may paint itself into a
    # corner, which is the whole reason the options come from the turns.
    my @ends;
    for my $how (0, -1, 'middle') {
        my @chosen;
        while (1) {
            my $match = $ui->_matching($turns, \@chosen);
            my $next = $ui->_next_moves($match, \@chosen);
            last unless @$next;
            my $index = $how eq 'middle' ? int(@$next / 2) : $how;
            push @chosen, $next->[$index];
        }
        my $match = $ui->_matching($turns, \@chosen);
        push @ends, $ui->_complete($match, \@chosen);
    }

    ok((!grep { !defined } @ends), 'each way round ends on a complete turn');
    ok((!grep { !$legal{ $_->key } } @ends), 'and on one the rules offered');
    is(scalar(grep { @{ $_->moves } == 0 } @ends), 0,
        'none of them forfeits a roll that could be played');
};

subtest 'the keys build a turn and it is played' => sub {
    plan tests => 4;
    my ($ui, $out) = picker(seed => 'build', keys => "\r\r\r\r");
    my $who = $ui->game->turn;
    my $turns = $ui->game->legal_turns;
    my $turn = $ui->_pick_turn($who, $turns);

    ok($turn, 'pressing enter until the dice run out gives a turn');
    ok(scalar(grep { $_->key eq $turn->key } @$turns),
        'and it is one of the legal ones, not one assembled here');
    ok($ui->game->play($turn), 'so the game accepts it');
    like(${$out}, qr/so far: /, 'the turn was shown being built');
};

subtest 'backspace takes a move back' => sub {
    plan tests => 2;
    # choose the first move, take it back, then choose the second instead
    my ($ui, $out) = picker(seed => 'undo', keys => "\r\x7f\e[B\r\r\r\r");
    my $who = $ui->game->turn;
    my $turns = $ui->game->legal_turns;
    my $first = $ui->_next_moves($turns, [])->[0]->notation;
    my $turn = $ui->_pick_turn($who, $turns);

    ok($turn, 'a turn still comes out');
    isnt($turn->moves->[0]->notation, $first,
        'and it does not start with the move that was taken back');
};

subtest 'backspace at the start is answered, not fatal' => sub {
    plan tests => 2;
    my ($ui, $out) = picker(seed => 'empty-undo', keys => "\x7f\r\r\r\r");
    my $turn = $ui->_pick_turn($ui->game->turn, $ui->game->legal_turns);
    like(${$out}, qr/nothing taken back/, 'it says there is nothing to take back');
    ok($turn, 'and the turn is still built');
};

subtest 'q and the end of the input both stop' => sub {
    plan tests => 2;
    my ($quit) = picker(seed => 'q', keys => 'q');
    is($quit->_pick_turn($quit->game->turn, $quit->game->legal_turns), undef,
        'q gives up the turn');

    my ($gone) = picker(seed => 'eof', keys => '');
    is($gone->_pick_turn($gone->game->turn, $gone->game->legal_turns), undef,
        'and so does running out of input, rather than hanging');
};

subtest 'the move under the cursor is marked on the board' => sub {
    plan tests => 5;
    my ($ui) = picker(seed => 'marks');
    my $who = $ui->game->turn;
    my ($move) = @{ $ui->_next_moves($ui->game->legal_turns, []) };

    my $mark = $ui->_move_marks($who, $who, [], $move);
    is($mark->{ $move->from }, 'from', 'where the checker leaves is marked');
    is($mark->{ $move->to }, $move->hit ? 'hit' : 'to', 'and where it lands');

    # the board can be pinned to the other side, and then the points of the
    # picture are not the points the move is written in
    my $other = Game::Backgammon::Board::other($who);
    my $flipped = $ui->_move_marks($other, $who, [], $move);
    is($flipped->{ 25 - $move->from }, 'from',
        "the other side's numbering is used when the board is drawn from it");
    is(scalar keys %$flipped, scalar keys %$mark, 'the same number of marks');

    # a move already chosen stays marked, so the turn so far is visible
    my $with = $ui->_move_marks($who, $who, [$move], undef);
    is($with->{ $move->to }, 'played', 'a move already chosen is marked as played');
};

subtest 'bearing off and the bar have no point to mark' => sub {
    plan tests => 2;
    my $game = Game::Backgammon->new(seed => seed_of('off'));
    my $board = $game->board;
    $board->set_point('white', $_, 0) for 1 .. 24;
    $board->set_point('black', $_, 0) for 1 .. 24;
    $board->set_point('white', 2, 2);
    $board->set_point('black', 1, 2);
    my ($ui) = picker(game => $game);

    my $off = Game::Backgammon::Move->new(
        player => 'white', from => 2, to => 'off', die => 2);
    my $mark = $ui->_move_marks('white', 'white', [], $off);
    is_deeply([sort keys %$mark], ['2'], 'bearing off marks the point it leaves only');

    my $bar = Game::Backgammon::Move->new(
        player => 'white', from => 'bar', to => 20, die => 5);
    $mark = $ui->_move_marks('white', 'white', [], $bar);
    is_deeply([sort keys %$mark], ['20'], 'and coming in marks only where it lands');
};

subtest 'the board is checkered when colour is on' => sub {
    plan tests => 5;
    my ($plain) = picker(seed => 'paint', colour => 0);
    unlike(join('', @{ $plain->board_lines('white') }), qr/\e/,
        'with colour off there is no escape anywhere');

    my ($painted) = picker(seed => 'paint', colour => 1);
    my $lines = $painted->board_lines('white');
    my @ground = ($lines->[1] =~ /\e\[(48;5;\d+)/g);
    is(scalar @ground, 12, 'every one of the twelve points of a row is painted');
    is(scalar(grep { $ground[$_] eq $ground[0] } grep { $_ % 2 == 0 } 0 .. 11), 6,
        'the alternate ones share a colour');
    isnt($ground[0], $ground[1], 'and a point is not the colour of its neighbour');

    $painted->highlight({ 13 => 'from' });
    my @marked = ($painted->board_lines('white')->[1] =~ /\e\[(48;5;\d+)/g);
    isnt($marked[0], $ground[0], 'a highlighted point is painted differently');
};

subtest 'picking is off where it cannot work' => sub {
    plan tests => 3;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $ui = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of('nokeys')),
        out => $fh, in => \*STDIN, ascii => 1, colour => 0, interactive => 0);
    is($ui->picking, 0, 'a terminal that was not asked to pick does not');
    is($ui->raw, 0, 'and is not put into cbreak mode');

    # the numbered list is still the fallback, and still offers every turn
    my $turns = $ui->game->legal_turns;
    my $offered = join "\n", @{ $ui->offer_lines($turns) };
    is(scalar(() = $offered =~ /\d+\)/g), scalar @$turns,
        'and the numbered list still offers every turn exactly once');
};

done_testing();
