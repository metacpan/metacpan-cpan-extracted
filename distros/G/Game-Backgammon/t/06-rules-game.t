#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Backgammon;
use Game::Backgammon::Board;
use Game::Backgammon::Result;
use Game::Backgammon::Rules qw(legal_turns apply_move single_moves);

# The rules of the game: hitting, the bar, bearing off, and how it ends.
#
# The endgame cases are built rather than played to. Bearing off with a
# higher roll, and being hit while doing it, are rare in a random game and
# common in a real one, so a suite that only plays games never exercises
# them.

sub seed_of { Digest::SHA::sha256($_[0]) }

# A position, with the fixture checked: putting black on a point white
# occupies would overwrite it (the array is signed), and a fixture that is
# not a position tests nothing.
sub board {
    my (%o) = @_;
    my $pos = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    for my $n (keys %{ $o{white} || {} }) { $pos->set_point('white', $n, $o{white}{$n}) }
    for my $n (keys %{ $o{black} || {} }) { $pos->set_point('black', $n, $o{black}{$n}) }
    $pos->to_bar('white', $o{white_bar}) if $o{white_bar};
    $pos->to_bar('black', $o{black_bar}) if $o{black_bar};
    $pos->to_off('white', $o{white_off}) if $o{white_off};
    $pos->to_off('black', $o{black_off}) if $o{black_off};
    my @wrong = $pos->consistent;
    die "t/06: the fixture is not a legal position: @wrong\n" if @wrong;
    return $pos;
}

# ---- hitting --------------------------------------------------------------------

subtest 'a blot is hit and goes to the bar' => sub {
    plan tests => 4;
    # black has ONE checker on white's 5 point (black's 20)
    my $pos = board(white => { 8 => 1 }, white_off => 14,
                    black => { 20 => 1, 10 => 14 });
    ok($pos->is_blot('white', 5), 'black has a blot on white\'s 5 point');

    my ($move) = grep { $_->to == 5 } single_moves($pos, 'white', 3);
    ok($move && $move->hit, 'the move onto it is marked as a hit');

    my $after = apply_move($pos, $move);
    is($after->bar('black'), 1, 'the checker is on the bar');
    is($after->mine_on('white', 5), 1, 'and white is standing there');
};

subtest 'two checkers are not a blot and cannot be landed on' => sub {
    plan tests => 2;
    my $pos = board(white => { 8 => 1 }, white_off => 14,
                    black => { 20 => 2, 10 => 13 });
    ok($pos->is_blocked('white', 5), 'two of theirs blocks the point');
    my @to5 = grep { $_->to == 5 } single_moves($pos, 'white', 3);
    is(scalar @to5, 0, 'so nothing may move there');
};

# ---- bearing off, the three cases ------------------------------------------------

subtest 'the exact roll bears a checker off' => sub {
    plan tests => 2;
    my $pos = board(white => { 4 => 2 }, white_off => 13, black => { 10 => 15 });
    my ($off) = grep { $_->is_off } single_moves($pos, 'white', 4);
    ok($off, 'a 4 bears off from the 4 point');
    is(apply_move($pos, $off)->off('white'), 14, 'and the tray has it');
};

subtest 'a higher roll bears off from the highest point, and only then' => sub {
    plan tests => 3;
    # the highest white checker is on the 4 point, so a 6 bears it off
    my $pos = board(white => { 4 => 2 }, white_off => 13, black => { 10 => 15 });
    my ($off) = grep { $_->is_off } single_moves($pos, 'white', 6);
    ok($off, 'a 6 bears off from the 4 point when nothing is higher');

    # now put a checker on the 6 point: the 4 point is no longer highest,
    # so a 5 may NOT bear off from it
    my $higher = board(white => { 6 => 1, 4 => 1 }, white_off => 13, black => { 10 => 15 });
    my @off = grep { $_->is_off && $_->from == 4 } single_moves($higher, 'white', 5);
    is(scalar @off, 0, 'but not while a checker sits higher than the die');

    my ($legal) = grep { $_->is_off } single_moves($higher, 'white', 6);
    ok($legal && $legal->from == 6, 'the 6 bears off the 6 point, exactly');
};

subtest 'a roll that is neither is played inside the home board' => sub {
    plan tests => 2;
    my $pos = board(white => { 6 => 2 }, white_off => 13, black => { 10 => 15 });
    my @moves = single_moves($pos, 'white', 2);
    is(scalar @moves, 1, 'one move');
    ok(!$moves[0]->is_off && $moves[0]->to == 4, 'and it is 6/4, not a bear off');
};

subtest 'being hit stops the bearing off' => sub {
    plan tests => 3;
    my $pos = board(white => { 6 => 1, 2 => 1 }, white_off => 13,
                    black => { 10 => 15 });
    ok($pos->all_home('white'), 'white is all home and may bear off');

    # the same position with one white checker on the bar
    my $hit = board(white => { 6 => 1, 2 => 1 }, white_bar => 1, white_off => 12,
                    black => { 10 => 15 });
    ok(!$hit->all_home('white'), 'a checker on the bar is not home');
    my @off = grep { $_->is_off } single_moves($hit, 'white', 6);
    is(scalar @off, 0, 'so nothing bears off until it comes back round');
};

# ---- the bar --------------------------------------------------------------------

subtest 'a checker on the bar enters before anything else moves' => sub {
    plan tests => 3;
    my $pos = board(white => { 13 => 5, 6 => 9 }, white_bar => 1, black => { 10 => 15 });
    my @moves = single_moves($pos, 'white', 3);
    is(scalar @moves, 1, 'only one move is offered');
    ok($moves[0]->is_bar, 'and it comes from the bar');
    is($moves[0]->to, 22, 'entering with a 3 lands on the 22 point');
};

# ---- the margin, from built positions --------------------------------------------

subtest 'the margin a finished position implies' => sub {
    plan tests => 3;

    # the loser has borne off: a single
    my $single = board(white => {}, white_off => 15,
                       black => { 10 => 13 }, black_off => 2);
    is(Game::Backgammon::Result->margin_for($single, 'white'), 'single',
       'a checker borne off makes it a single');

    # nothing borne off, and nothing of theirs in white's home or on the bar
    my $gammon = board(white => {}, white_off => 15, black => { 10 => 15 });
    is(Game::Backgammon::Result->margin_for($gammon, 'white'), 'gammon',
       'none borne off is a gammon');

    # nothing borne off AND a checker still in the winner's home board,
    # which is white's 1 to 6 and so black's 19 to 24
    my $bg = board(white => {}, white_off => 15, black => { 22 => 1, 10 => 14 });
    is(Game::Backgammon::Result->margin_for($bg, 'white'), 'backgammon',
       'and one still in the winner\'s home board is a backgammon');
};

subtest 'a checker on the bar is a backgammon too' => sub {
    plan tests => 1;
    my $pos = board(white => {}, white_off => 15,
                    black => { 10 => 14 }, black_bar => 1);
    is(Game::Backgammon::Result->margin_for($pos, 'white'), 'backgammon',
       'still on the bar counts');
};

# ---- finishing from outside ------------------------------------------------------

subtest 'a resignation, a timeout and an abandoned game' => sub {
    plan tests => 5;
    for my $reason (qw(resign timeout abandoned)) {
        my $g = Game::Backgammon->new(seed => seed_of("finish-$reason"));
        my $r = $g->finish(winner => 'black', reason => $reason);
        is($r->reason, $reason, "a game can be finished by $reason");
    }

    my $g = Game::Backgammon->new(seed => seed_of('resign'));
    is($g->finish(winner => 'black')->margin, 'single',
       'a resignation concedes a single: there is no cube to negotiate');

    ok(!$g->finish(winner => 'white'), 'and a finished game cannot be finished again');
};

# ---- whole games -----------------------------------------------------------------

subtest 'games play to the end and the invariant holds every turn' => sub {
    my @seeds = map { "game-$_" } 1 .. 8;
    plan tests => scalar(@seeds) * 3;

    for my $name (@seeds) {
        my $g = Game::Backgammon->new(seed => seed_of($name));
        my ($turns, $broke) = (0, '');
        while ($g->status eq 'active' && $turns++ < 5000) {
            my $legal = $g->legal_turns;
            $g->play($legal->[ $turns % scalar @$legal ]) or do { $broke = $@->message; last };
            my @wrong = $g->board->consistent;
            if (@wrong) { $broke = "@wrong"; last }
        }
        is($broke, '', "$name: fifteen checkers a side, every turn");
        is($g->status, 'finished', "$name: and it finished");
        is($g->board->off($g->result->winner), 15, "$name: the winner bore off fifteen");
    }
};

subtest 'a game replays from its seed and its turns' => sub {
    plan tests => 3;
    my $g = Game::Backgammon->new(seed => seed_of('replay'));
    my $n = 0;
    while ($g->status eq 'active' && $n++ < 5000) {
        my $legal = $g->legal_turns;
        $g->play($legal->[0]) or last;
    }
    ok($g->status eq 'finished', 'a game was played');

    my $again = Game::Backgammon->replay(seed => seed_of('replay'), turns => $g->to_log);
    is_deeply($again->board->points, $g->board->points, 'and it replays to the same board');
    is($again->result->margin, $g->result->margin, 'with the same margin');
};

subtest 'a log the seed does not produce is refused' => sub {
    plan tests => 1;
    my $g = Game::Backgammon->new(seed => seed_of('tamper'));
    $g->play($g->legal_turns->[0]);
    my $log = $g->to_log;
    push @$log, '24/23 24/23';          # a turn those dice never allowed
    my $err = '';
    eval { Game::Backgammon->replay(seed => seed_of('tamper'), turns => $log); 1 }
        or $err = $@;
    like($err, qr/does not replay/, 'the seed is the authority, not the log');
};

# ---- what play refuses -----------------------------------------------------------

subtest 'play refuses what the rules did not offer' => sub {
    plan tests => 3;
    my $g = Game::Backgammon->new(seed => seed_of('refuse'));

    ok(!$g->play('24/23 24/23'), 'a turn that is not on offer is refused');
    is($@->code, 'not_legal', 'as not_legal');

    ok(!$g->play('nonsense'), 'and a line that is not notation is refused too');
};

done_testing();
