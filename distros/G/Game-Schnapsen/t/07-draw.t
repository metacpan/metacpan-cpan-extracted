#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(name_of);
use Game::Schnapsen::Variant qw(variants hand_size);
use Game::Schnapsen::Deck qw(deal_for draw_count);
use Game::Schnapsen::Deal ();

# The draw is not a move and nobody chooses anything about it, so the only
# things to get wrong are the ORDER and the COUNT. Both give a legal, replayable,
# entirely plausible deal when wrong, which is why they are tested directly
# rather than left to fall out of a game playing through.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();

# Every loop that plays a deal out is bounded. A deal is at most twelve tricks,
# so thirty is far past any real one and far short of waiting for ever.
#
# This is here because of a mutation that made only one player draw per trick.
# The hands then go uneven, one empties while the other still holds cards,
# `over` is false for ever and `legal` is empty, and the suite HUNG rather than
# failing: the mutation run had to be killed. A test that cannot fail is worse
# than one that fails wrongly, because nothing tells you it has stopped working.
use constant MAX_TRICKS => 30;

sub fresh {
    my ($v, $n) = @_;
    return Game::Schnapsen::Deal->build(
        variant => $v, seed => seed("draw $v"), number => $n || 1, dealer => 'p1');
}

# Sixty-Six lets a player close the talon BEFORE drawing, so the draw cannot be
# automatic there: after a trick the winner is offered `close` or `draw`, and
# `draw` is how you decline to close. Schnapsen has no such moment and draws by
# itself. These helpers always decline, so every deal below is played exactly as
# it was before the declarations existed.
sub settle_draw {
    my ($d) = @_;
    return unless $d->pending_draw;
    $d->apply($d->turn, { kind => 'draw' });
    return;
}

# Play one trick, with the leader choosing $lead and the follower choosing the
# first card it is allowed. Returns the seat that won. Leaves no draw pending,
# so the deal is in the same shape at the end as at the start.
sub one_trick {
    my ($d, $lead) = @_;
    my $leader = $d->turn;
    $lead //= $d->hand_of($leader)->cards->[0];
    $d->apply($leader, { kind => 'lead', card => $lead });
    my $other = $d->turn;
    my $answer = $d->legal($other)->[0]{card};
    $d->apply($other, { kind => 'follow', card => $answer });
    my $winner = $d->last_trick->{winner};
    settle_draw($d);
    return $winner;
}

subtest 'the winner of a trick draws first' => sub {
    # With an odd number of face-down cards this decides who gets the turn-up,
    # which is the one talon card both players have seen. Getting it backwards
    # is invisible in play.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $deal = deal_for(seed("draw $v"), 1, $v);
        my @order = @{ $deal->{talon} };

        my $winner = one_trick($d);
        my $loser  = $winner eq 'p1' ? 'p2' : 'p1';

        ok($d->hand_of($winner)->has_card($order[0]),
           "$v: the winner took the top of the talon, the " . name_of($order[0]));
        ok($d->hand_of($loser)->has_card($order[1]),
           "$v: and the loser the one under it, the " . name_of($order[1]));
    }
};

subtest 'the turn-up is the last card drawn, and goes to a loser' => sub {
    # Both rulesets have the trump card lying face up under the talon and going
    # to whoever draws last. Since the winner always draws first, that is always
    # the LOSER of the final drawing trick.
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $turn_up = $d->turn_up;
        my $draws = draw_count($v) / 2;

        my $last_winner;
        $last_winner = one_trick($d) for 1 .. $draws;
        my $last_loser = $last_winner eq 'p1' ? 'p2' : 'p1';

        is($d->talon_left, 0, "$v: after $draws tricks there is nothing left to draw");
        is($d->turn_up, undef, "$v: the turn-up has been taken");
        ok($d->hand_of($last_loser)->has_card($turn_up),
           "$v: by the loser of the last drawing trick");
        is($d->phase, 2, "$v: and the deal is in phase 2");
    }
};

subtest 'hands return to size after every trick until the talon empties' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $size = hand_size($v);
        my (@wrong, $tricks);
        $tricks = 0;
        while (!$d->over && $tricks < MAX_TRICKS) {
            one_trick($d);
            $tricks++;
            if ($d->draw_left) {
                push @wrong, "trick $tricks"
                    unless $d->hand_of('p1')->count == $size
                        && $d->hand_of('p2')->count == $size;
            }
            else {
                # Once nothing can be drawn the hands shrink together, one card
                # each per trick, and must stay equal all the way down.
                push @wrong, "trick $tricks (uneven)"
                    unless $d->hand_of('p1')->count == $d->hand_of('p2')->count;
            }
        }
        is_deeply(\@wrong, [], "$v: every hand was the right size at every point");
        is($tricks, $size + draw_count($v) / 2,
           "$v: a deal played out is $tricks tricks");
    }
};

subtest 'no card is ever lost, duplicated or invented' => sub {
    # THE INVARIANT THAT STANDS IN FOR A PERFT. There is no move-count oracle
    # for this family, so what is asserted after EVERY move of every deal is
    # that the pack is conserved and that the card points still add to 120.
    #
    # It is the cheapest assertion in the distribution and it is the one that
    # catches a draw taken from the wrong end, a card removed from a hand twice,
    # and a trick counted to both seats.
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@leaks, @points, @stuck, $checks);
        for my $n (1 .. 25) {
            my $d = Game::Schnapsen::Deal->build(
                variant => $v, seed => seed("conserve $v $n"), number => $n, dealer => 'p1');
            my $pack = join ',', @{ Game::Schnapsen::Deck::pack_for($v) };

            my $look = sub {
                my ($where) = @_;
                $checks++;
                my @all = (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
                           @{ $d->talon },
                           (defined $d->turn_up ? ($d->turn_up) : ()),
                           (defined $d->lead ? ($d->lead) : ()),
                           map { ($_->{lead}, $_->{follow}) } @{ $d->tricks });
                push @leaks, "$n $where: " . scalar(@all) . ' cards'
                    unless join(',', sort { $a <=> $b } @all) eq $pack;

                my $in_play = 0;
                $in_play += Game::Schnapsen::Card::points_of($_)
                    for (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
                         @{ $d->talon },
                         (defined $d->turn_up ? ($d->turn_up) : ()),
                         (defined $d->lead ? ($d->lead) : ()));
                my $total = $in_play + $d->points_of('p1') + $d->points_of('p2');
                push @points, "$n $where: $total" unless $total == 120;
            };

            $look->('start');
            my $spins = 0;
            while (!$d->over && $spins++ < MAX_TRICKS) {
                my $leader = $d->turn;
                $d->apply($leader, { kind => 'lead', card => $d->hand_of($leader)->cards->[0] });
                $look->('mid-trick');
                my $other = $d->turn;
                my $answer = $d->legal($other)->[0];
                unless ($answer) { push @stuck, "$n: nothing legal at trick $spins"; last }
                $d->apply($other, { kind => 'follow', card => $answer->{card} });
                $look->('trick taken, draw pending');
                settle_draw($d);
                $look->('after trick');
            }
            push @stuck, "$n: still running after " . MAX_TRICKS . ' tricks' unless $d->over;
        }
        # The cap has to be an ASSERTION and not just an escape, or a deal that
        # never ends passes this subtest by conserving cards it is not playing.
        is_deeply(\@stuck, [], "$v: every deal ran out of cards and stopped");
        is_deeply(\@leaks, [], "$v: the pack is whole after every move");
        is_deeply(\@points, [], "$v: and the 120 card points are all accounted for");
        cmp_ok($checks, '>', 500, "$v: over $checks positions, so the sweep meant something");
    }
};

subtest 'the two numbers a closed talon needs' => sub {
    # talon_left counts the cards that are there; draw_left is how many may be
    # drawn. They are equal until somebody closes, which is phase 03's work, so
    # today this only pins that the distinction exists and that phase reads the
    # second one.
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        is($d->talon_left, draw_count($v), "$v: the talon starts full");
        is($d->draw_left, $d->talon_left, "$v: and everything in it may be drawn");
        is($d->phase, 1, "$v: which is what makes it phase 1");
    }
};

done_testing();
