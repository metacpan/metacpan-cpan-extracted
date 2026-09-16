#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin;
use Game::Gin::Deadwood qw(deadwood);
use Game::Gin::Scoring qw(BOX_BONUS GAME_BONUS);

# A whole match, played through the engine rather than assembled from hand
# results, so that the deal rotation, the deal numbering and the running score
# are exercised together.

sub seed { return Digest::SHA::sha256("match:$_[0]") }

# A player who knocks when offered and otherwise throws whatever leaves the
# least deadwood. Not a bot, and deliberately not in lib/: phase 05 writes the
# bot. This is the smallest policy that finishes a match, which is all a test
# of the match machinery needs.
sub sensible {
    my ($g, $seat) = @_;
    my $legal = $g->legal($seat);
    return undef unless @$legal;
    my ($big) = grep { $_->{kind} eq 'big_gin' } @$legal;
    return $big if $big;
    my ($knock) = grep { $_->{knock} } @$legal;
    return $knock if $knock;
    my @discard = grep { $_->{kind} eq 'discard' } @$legal;
    if (@discard) {
        my $hand = $g->deal->hand_of($seat)->cards;
        my @ranked = sort { $a->{left} <=> $b->{left} }
                     map { my $c = $_->{card};
                           { move => $_, left => deadwood([ grep { $_ != $c } @$hand ]) } }
                     @discard;
        return $ranked[0]{move};
    }
    return $legal->[0];
}

sub play_out {
    my ($n, $cap) = @_;
    my $g = Game::Gin->build(seed => seed($n), dealer => 'p1');
    my $moves = 0;
    while (!$g->over && $moves < ($cap || 20_000)) {
        my $seat = $g->turn or last;
        my $move = sensible($g, $seat) or last;
        my @out = $g->apply($seat, $move);
        return ($g, $moves, $out[0]) if ref $out[0] eq 'Game::Gin::Error';
        $moves++;
    }
    return ($g, $moves, undef);
}

# ---- a match finishes, and finishes correctly ---------------------------------------------

subtest 'a match plays to a result' => sub {
    plan tests => 6;
    my ($g, $moves, $err) = play_out(1);
    is($err, undef, 'no move was refused');
    ok($g->over, "the match finished in $moves moves");

    my $r = $g->result;
    ok($r->{winner}, 'somebody won');
    cmp_ok($r->{hand_points}{ $r->{winner} }, '>=', 100,
           'and it is the seat that reached the target');
    cmp_ok($r->{hand_points}{ $r->{loser} }, '<', 100,
           'the other seat did not');
    cmp_ok(scalar @{ $g->hands }, '>', 1, 'over several deals');
};

subtest 'the running score is the hand points and nothing else' => sub {
    plan tests => 2;
    my ($g) = play_out(2);
    my $r = $g->result;
    is_deeply($g->scores, $r->{hand_points},
              'scores() is the hand points, with no bonus folded in');
    # The bonuses only exist at the end, so the totals must differ from the
    # running score for the winner: points, boxes and the game bonus.
    cmp_ok($r->{totals}{ $r->{winner} }, '>', $g->scores->{ $r->{winner} },
           'and the final total is larger, because the bonuses are added once');
};

# ---- the deal rotates the way the source says ------------------------------------------------

subtest 'the winner of a hand deals the next' => sub {
    plan tests => 3;
    # WATCHED AS IT HAPPENS, not reconstructed afterwards. The first version
    # of this compared $g->dealer once the match was over, which is the dealer
    # of the LAST deal and is never updated again, and it passed whether the
    # rule was "the winner deals" or "the loser deals". A rotation is a
    # transition, so the test has to be at the transition.
    my $g = Game::Gin->build(seed => seed(3), dealer => 'p1');
    my ($checked, @wrong) = (0);
    my $moves = 0;

    while (!$g->over && $moves++ < 20_000) {
        my $seat = $g->turn or last;
        my $before = $g->number;
        my $move = sensible($g, $seat) or last;
        $g->apply($seat, $move);

        next if $g->over || $g->number == $before;

        # A deal just ended and another began.
        my $just = $g->hands->[-1];
        $checked++;
        my $want = $just->{winner} || 'p1';   # a cancelled hand leaves it alone
        push @wrong, { hand => $before, winner => $just->{winner}, dealer => $g->dealer }
            if $g->dealer ne $want && @wrong < 5;
    }

    ok($g->over, 'the match finished');
    cmp_ok($checked, '>', 1, "$checked deal changes were watched");
    is_deeply(\@wrong, [], 'and each new deal was dealt by the winner of the last hand')
        or diag(explain(\@wrong));
};

subtest 'each deal is shuffled separately' => sub {
    plan tests => 2;
    my $g = Game::Gin->build(seed => seed(4), dealer => 'p1');
    my $first = join ',', @{ $g->deal->hand_of('p1')->sorted };
    is($g->number, 1, 'the first deal is number one');

    # Drive it to the second deal and compare. A match that shuffled once
    # would deal the same twenty cards every hand, which reads as luck.
    my $moves = 0;
    while (!$g->over && $g->number == 1 && $moves++ < 20_000) {
        my $seat = $g->turn or last;
        my $move = sensible($g, $seat) or last;
        $g->apply($seat, $move);
    }
    my $second = join ',', @{ $g->deal->hand_of('p1')->sorted };
    isnt($second, $first, 'the second deal is a different hand');
};

# ---- conservation ------------------------------------------------------------------------------

subtest 'every point in a final total can be accounted for' => sub {
    my $MATCHES = $ENV{GIN_MATCHES} || 40;
    plan tests => 3;

    my ($checked, @bad) = (0);
    for my $n (1 .. $MATCHES) {
        my ($g, $moves, $err) = play_out($n);
        next unless $g->over;
        $checked++;
        my $r = $g->result;

        for my $seat (qw(p1 p2)) {
            my $points = $r->{hand_points}{$seat};
            $points *= 2 if $r->{shutout};
            my $want = $points
                     + BOX_BONUS * $r->{hands_won}{$seat}
                     + (($r->{winner} // '') eq $seat ? GAME_BONUS : 0);
            push @bad, { match => $n, seat => $seat, got => $r->{totals}{$seat}, want => $want }
                if $r->{totals}{$seat} != $want && @bad < 5;
        }

        # Hands won must match the hands that were actually won, and a
        # cancelled hand must be counted for nobody.
        my %won;
        $won{ $_->{winner} }++ for grep { $_->{winner} } @{ $g->hands };
        push @bad, { match => $n, seat => 'count', got => $r->{hands_won}{p1}, want => ($won{p1} || 0) }
            if $r->{hands_won}{p1} != ($won{p1} || 0) && @bad < 5;
    }

    is($checked, $MATCHES, "$checked matches finished and were accounted for");
    cmp_ok($checked, '>', 20, 'which is enough of them to mean something');
    is_deeply(\@bad, [], 'every total is its points, its boxes and its game bonus')
        or diag(explain(\@bad));
};

done_testing();
