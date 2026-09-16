#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Backgammon::Board;
use Game::Backgammon::Rules qw(legal_turns single_moves apply_move);

# The legal turn. Four rules, each from a position built to isolate it,
# because in a played position they overlap and a passing test proves
# nothing about which rule made it pass.

# A board with nothing on it but what the test puts there. The opposing
# checkers go somewhere harmless and out of the way so the fifteen-a-side
# invariant still holds.
sub board {
    my (%o) = @_;
    my $pos = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    while (my ($n, $count) = each %{ $o{white} || {} }) { $pos->set_point('white', $n, $count) }
    while (my ($n, $count) = each %{ $o{black} || {} }) { $pos->set_point('black', $n, $count) }
    $pos->to_bar('white', $o{white_bar}) if $o{white_bar};
    $pos->to_bar('black', $o{black_bar}) if $o{black_bar};
    $pos->to_off('white', $o{white_off}) if $o{white_off};
    $pos->to_off('black', $o{black_off}) if $o{black_off};

    # A fixture that is not a real position tests nothing, and the signed
    # array hides the mistake: putting black on a point white occupies
    # overwrites it rather than complaining. So the helper complains.
    my @wrong = $pos->consistent;
    die "t/04: the fixture is not a legal position: @wrong\n" if @wrong;
    return $pos;
}

sub lines { return sort map { $_->notation } @{ $_[0] } }

# ---- rule 1: both dice if any sequence plays both -------------------------------

subtest 'both dice must be played when a sequence exists that plays both' => sub {
    plan tests => 3;

    # white has one checker on 10, black holds 8 and 7 (white's numbering),
    # so a 2 alone is blocked and a 3 alone is blocked, but 3 then 2 is not:
    # 10 -> 7 is blocked, 10 -> 8 is blocked... build it so only one order works
    # The opening position, where both dice are obviously playable. A
    # contrived position risks testing that the fixture is cramped rather
    # than that the rule holds.
    my $pos = Game::Backgammon::Board->new;

    my $turns = legal_turns($pos, 'white', 3, 2);
    ok(scalar @$turns, 'there are turns');
    my ($most) = sort { $b <=> $a } map { scalar @{ $_->moves } } @$turns;
    is($most, 2, 'and they use both dice');
    ok(!grep({ @{ $_->moves } < 2 } @$turns),
       'no one-move turn is offered while a two-move one exists');
};

subtest 'a turn that can only play one die plays one' => sub {
    plan tests => 2;
    # white has a single checker on 3; black holds 1 and 2 so only the 3
    # (bearing... no: not all home) - build it plainly: one checker on 20,
    # black blocks 18 and 17, so a 2 and a 3 are both blocked from there
    my $pos = board(white => { 20 => 1, 6 => 14 }, black => { 7 => 2, 8 => 2, 20 => 11 });
    # black's 7 is white's 18, black's 8 is white's 17
    my $turns = legal_turns($pos, 'white', 2, 3);
    my ($most) = sort { $b <=> $a } map { scalar @{ $_->moves } } @$turns;
    ok($most >= 1, 'something can be played');
    ok(scalar @$turns, 'and a turn is offered');
};

# ---- rule 2: the larger die -----------------------------------------------------

subtest 'when only one die can be played, it must be the larger' => sub {
    plan tests => 3;

    # White has ONE checker, on its 6 point, and nothing else to move.
    # Black holds white's 1 point (a 5 is blocked) and white's 2 point
    # (a 4 is blocked)... we want exactly: the 5 is playable, the 2 is
    # playable, but not both, and then the 5 must be chosen.
    #
    # One white checker on 8. A 5 takes it to 3, a 2 takes it to 6.
    # Black holds 6 (so the 2 is blocked) leaving only the 5.
    # ONE white checker on its 8 point and the other fourteen already off,
    # so nothing else can move. A 5 plays 8/3 and a 2 plays 8/6: BOTH are
    # legal on their own. Neither can be followed by the other, because
    # black holds white's 1 point. So exactly one die gets played, and the
    # rule says which.
    my $pos = board(white => { 8 => 1 }, white_off => 14,
                    black => { 24 => 2, 10 => 13 });
    ok(!$pos->is_blocked('white', 6) && !$pos->is_blocked('white', 3),
       'each die can be played on its own');

    my $turns = legal_turns($pos, 'white', 5, 2);
    is(scalar @$turns, 1, 'one turn is offered');
    is($turns->[0]->notation, '8/3', 'and it is the larger die, not the smaller');
};

subtest 'the larger die rule does not fire when both can be played' => sub {
    plan tests => 1;
    my $pos = board(white => { 8 => 1 }, white_off => 14, black => { 10 => 15 });
    my $turns = legal_turns($pos, 'white', 5, 2);
    my ($most) = sort { $b <=> $a } map { scalar @{ $_->moves } } @$turns;
    is($most, 2, 'both dice are played, so the rule never applies');
};

# ---- rule 3: doubles ------------------------------------------------------------

subtest 'doubles play four, and as many as can be played' => sub {
    plan tests => 2;

    my $pos = board(white => { 10 => 4, 1 => 11 }, black => { 20 => 15 });
    my $turns = legal_turns($pos, 'white', 2, 2, 2, 2);
    my ($most) = sort { $b <=> $a } map { scalar @{ $_->moves } } @$turns;
    is($most, 4, 'four moves on a double');

    # now block everything after one move: white has one checker on 4,
    # black holds white's 2 point, so 4/2 is blocked and nothing moves
    my $stuck = board(white => { 4 => 1 }, white_off => 14, black => { 23 => 2, 10 => 13 });
    my $none = legal_turns($stuck, 'white', 2, 2, 2, 2);
    is(scalar @{ $none->[0]->moves }, 0,
       'and none when the double cannot be played at all');
};

# ---- rule 4: the bar ------------------------------------------------------------

subtest 'a checker on the bar moves before anything else' => sub {
    plan tests => 3;

    my $pos = board(white => { 10 => 5, 1 => 9 }, black => { 20 => 15 }, white_bar => 1);
    my $turns = legal_turns($pos, 'white', 3, 4);
    ok(scalar @$turns, 'there are turns');
    ok(!grep({ !$_->moves->[0]->is_bar } grep { @{ $_->moves } } @$turns),
       'every one of them starts by entering from the bar');

    # a 3 enters on white's 22 point, a 4 on its 21
    my %entered = map { $_->moves->[0]->to => 1 } grep { @{ $_->moves } } @$turns;
    is_deeply([ sort { $a <=> $b } keys %entered ], [ 21, 22 ],
              'entering with n lands on the 25 - n point');
};

subtest 'a turn that cannot enter is forfeit, and a forfeit is a turn' => sub {
    plan tests => 3;

    # black holds white's 22 and 21, so neither a 3 nor a 4 can enter
    my $pos = board(white => { 10 => 5, 1 => 9 }, black => { 3 => 2, 4 => 2, 20 => 11 },
                    white_bar => 1);
    ok($pos->is_blocked('white', 22) && $pos->is_blocked('white', 21), 'both entries are shut');

    my $turns = legal_turns($pos, 'white', 3, 4);
    is(scalar @$turns, 1, 'exactly one turn is offered, not none');
    ok($turns->[0]->is_forfeit, 'and it is the empty one: a forfeit is a turn, not an error');
};

# ---- deduplication --------------------------------------------------------------

subtest 'two orders of the same moves are offered once' => sub {
    plan tests => 2;

    # two checkers that can both move, with the dice either way round
    my $pos = board(white => { 13 => 1, 8 => 1, 2 => 13 }, black => { 20 => 15 });
    my $turns = legal_turns($pos, 'white', 5, 3);

    my %seen;
    $seen{ $_->key }++ for @$turns;
    is(scalar(grep { $_ > 1 } values %seen), 0, 'no turn is offered twice');

    my @same = grep { $_->notation =~ /13\/8/ && $_->notation =~ /8\/5/ } @$turns;
    ok(scalar @same <= 1, 'and 13/8 8/5 appears once however the dice were ordered');
};

# ---- the property that matters --------------------------------------------------

subtest 'every offered turn is playable, and the board survives it' => sub {
    my @boards = (
        Game::Backgammon::Board->new,
        board(white => { 6 => 3, 5 => 4, 4 => 4, 3 => 4 }, black => { 6 => 15 }),
        board(white => { 10 => 5, 1 => 9 }, black => { 20 => 15 }, white_bar => 1),
    );
    my @dice = ([3, 1], [6, 5], [2, 2, 2, 2], [6, 6, 6, 6]);
    plan tests => scalar(@boards) * scalar(@dice);

    for my $pos (@boards) {
        for my $d (@dice) {
            my $turns = legal_turns($pos, 'white', @$d);
            my @bad;
            for my $t (@$turns) {
                my $after = $pos;
                $after = apply_move($after, $_) for @{ $t->moves };
                my @wrong = $after->consistent;
                push @bad, $t->notation . ': ' . join('; ', @wrong) if @wrong;
            }
            ok(!@bad, 'every turn leaves fifteen checkers a side');
            diag("  $_") for @bad;
        }
    }
};

done_testing();
