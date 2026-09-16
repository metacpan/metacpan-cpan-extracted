#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Digest::SHA ();

use Game::Gin::Card qw(id_of name_of rank_of suit_of deadwood_of CARDS);
use Game::Gin::Deadwood qw(best deadwood can_knock is_gin KNOCK_AT);
use Game::Gin::Deck qw(order_for);

# The least deadwood in a hand is the one function the whole game rests on, so
# it is checked against a second implementation that shares nothing with it.
#
# THE ORACLE BELOW DOES NOT CALL Game::Gin::Meld. It has its own meld
# predicate and its own recursion, because an oracle built on the same
# enumeration would agree with it about any bug in that enumeration and the
# comparison would prove nothing. That failure has a name in this repo: the
# probe sharing the bug.

sub h { return [ map { id_of($_) } @_ ] }

# ---- the oracle: slow, obvious, and independent ---------------------------------------

# Its own is_meld, written from the rules rather than imported.
sub _slow_is_meld {
    my (@c) = @_;
    return 0 if @c < 3;
    my @rank = sort { $a <=> $b } map { rank_of($_) } @c;
    my @suit = map { suit_of($_) } @c;

    # a set: one rank, no repeated suit
    my %s;
    my $one_rank = !grep { $_ != $rank[0] } @rank;
    my $no_dupe_suit = !grep { $s{$_}++ } @suit;
    return 1 if $one_rank && $no_dupe_suit && @c <= 4;

    # a run: one suit, consecutive ranks
    return 0 if grep { $_ ne $suit[0] } @suit;
    for my $i (1 .. $#rank) { return 0 unless $rank[$i] == $rank[ $i - 1 ] + 1 }
    return 1;
}

sub _combos {
    my ($list, $k) = @_;
    return ([]) if $k == 0;
    return () if @$list < $k;
    my ($first, @rest) = @$list;
    return (( map { [ $first, @$_ ] } _combos(\@rest, $k - 1) ), _combos(\@rest, $k));
}

# The most deadwood value that can be melded. Recursive, exhaustive, memoised
# only so a large sweep finishes; the memo is on the exact card list and so
# cannot change an answer.
my %SLOW;
sub _slow_melded {
    my (@c) = @_;
    return 0 if @c < 3;
    my $key = join ',', @c;
    return $SLOW{$key} if exists $SLOW{$key};

    my ($first, @rest) = @c;
    my $best = _slow_melded(@rest);                 # leave `first` unmelded
    for my $size (2 .. scalar @rest) {
        for my $combo (_combos(\@rest, $size)) {
            my @group = ($first, @$combo);
            next unless _slow_is_meld(@group);
            my %in = map { $_ => 1 } @$combo;
            my $v = 0;
            $v += deadwood_of($_) for @group;
            my $rest = _slow_melded(grep { !$in{$_} } @rest);
            $best = $v + $rest if $v + $rest > $best;
        }
    }
    return $SLOW{$key} = $best;
}

sub slow_deadwood {
    my ($cards) = @_;
    my @sorted = sort { $a <=> $b } @$cards;
    my $total = 0;
    $total += deadwood_of($_) for @sorted;
    return $total - _slow_melded(@sorted);
}

# ---- the answers somebody can check by eye -----------------------------------------------

subtest 'hands worked out by hand' => sub {
    plan tests => 7;

    is(deadwood(h(qw(KS))), 10, 'a lone king is ten');
    is(deadwood(h(qw(KS AS))), 11, 'a king and an ace is eleven');
    is(deadwood(h(qw(2S 3S 4S))), 0, 'a run melds completely');
    is(deadwood(h(qw(7S 7H 7D))), 0, 'and so does a set');

    # The case the sub-melds exist for, and the reason best() is not greedy.
    #
    #   7S 7H 7D 7C 5S 6S      thirty-nine points in the hand
    #
    # Greedy takes the four sevens, worth 28, and is left with 5S 6S: eleven.
    # The right answer breaks the set, melds 7H 7D 7C and runs 5S 6S 7S, and
    # is left with nothing at all.
    is(deadwood(h(qw(7S 7H 7D 7C 5S 6S))), 0,
       'breaking a four of a kind to finish a run leaves nothing');

    is(deadwood(h(qw(AS 2S 3S 7H 7D 7C KS))), 10,
       'two melds and a king left over');

    # A ten-card hand that melds completely: gin.
    ok(is_gin(h(qw(AS 2S 3S 4S 7H 7D 7C 9C TC JC))), 'a hand with no unmatched card is gin');
};

subtest 'the knock threshold is a boundary, so it is tested at the boundary' => sub {
    plan tests => 4;
    is(KNOCK_AT, 10, 'the threshold is ten');
    ok(can_knock(h(qw(KS))),        'ten exactly may knock');
    ok(!can_knock(h(qw(KS AS))),    'eleven may not');
    ok(can_knock(h(qw(2S 3S 4S))),  'and nothing at all certainly may');
};

subtest 'what best() reports alongside the number' => sub {
    plan tests => 4;
    my $b = best(h(qw(7S 7H 7D 7C 5S 6S)));
    is($b->{deadwood}, 0, 'no deadwood');
    is(scalar @{ $b->{melds} }, 2, 'in two melds');
    is_deeply($b->{unmatched}, [], 'with nothing unmatched');

    my $c = best(h(qw(AS 2S 3S KH)));
    is_deeply([ map { name_of($_) } @{ $c->{unmatched} } ], ['KH'],
              'and the leftovers are named');
};

subtest 'an empty hand is nothing, not a crash' => sub {
    plan tests => 2;
    is(deadwood([]), 0, 'no cards is no deadwood');
    is_deeply(best([])->{melds}, [], 'and no melds');
};

# ---- the sweep: fast against slow -----------------------------------------------------------

# Hands are drawn from real deals rather than uniformly at random, and the
# reason is worth stating: a uniform eleven-card hand usually has nothing
# interesting in it, so a uniform sweep spends its time confirming that a hand
# with no melds has no melds. Dealt hands are no better, so the sweep also
# builds hands SEEDED TOWARDS overlap, where a card is wanted by both a set
# and a run, which is where every real disagreement lives.
sub dealt_hand {
    my ($n, $size) = @_;
    my $order = order_for(Digest::SHA::sha256("sweep:$n"), 1 + ($n % 5));
    return [ @{$order}[ 0 .. $size - 1 ] ];
}

sub overlapping_hand {
    my ($n, $size) = @_;
    # a rank and a suit, then most of that set and some of that run
    my $rank = 2 + ($n % 11);              # 2..12, so a run fits either side
    my $suit = int($n / 11) % 4;
    my @hand = (
        $suit * 13 + $rank,                          # the shared card
        (($suit + 1) % 4) * 13 + $rank,
        (($suit + 2) % 4) * 13 + $rank,
        (($suit + 3) % 4) * 13 + $rank,
        $suit * 13 + $rank - 1,
        $suit * 13 + $rank + 1,
    );
    my %in = map { $_ => 1 } @hand;
    my $order = order_for(Digest::SHA::sha256("overlap:$n"), 1);
    for my $c (@$order) {
        last if @hand >= $size;
        push @hand, $c unless $in{$c}++;
    }
    return [ @hand[ 0 .. $size - 1 ] ];
}

subtest 'the fast answer is the right answer' => sub {
    # MEASURED: the oracle runs at about 73 hands a second, because it is
    # exhaustive and was written to be obviously correct rather than quick.
    # Making it fast would defeat the purpose of having it, so the routine
    # sweep is small and the big one is the gate's job: GIN_SWEEP=100000
    # is roughly 45 minutes and belongs in phase 08, not in `make test`.
    my $HANDS = $ENV{GIN_SWEEP} || 250;
    plan tests => 4;

    my ($checked, @wrong) = (0);
    my $started = Time::HiRes::time();

    for my $n (1 .. $HANDS) {
        for my $hand (dealt_hand($n, 11), overlapping_hand($n, 11)) {
            $checked++;
            my ($fast, $slow) = (deadwood($hand), slow_deadwood($hand));
            push @wrong, { hand => join(' ', map { name_of($_) } @$hand),
                           fast => $fast, slow => $slow }
                if $fast != $slow && @wrong < 5;
        }
    }
    my $took = Time::HiRes::time() - $started;

    # The count first and separately. A sweep whose loop never ran agrees with
    # the oracle about nothing at all and passes every assertion inside it.
    is($checked, $HANDS * 2, "$checked hands were compared");
    cmp_ok($checked, '>', 400, 'which is enough of them to catch a regression');
    is_deeply(\@wrong, [], 'the fast answer never differs from the brute force')
        or diag(explain(\@wrong));

    # Half the sweep is deliberately awkward hands. If that generator ever
    # stops producing overlap the sweep quietly becomes half as useful, so it
    # is checked rather than assumed.
    my $with_choice = 0;
    for my $n (1 .. 200) {
        my $b = best(overlapping_hand($n, 11));
        $with_choice++ if @{ $b->{melds} } >= 2;
    }
    cmp_ok($with_choice, '>', 150,
           'and the awkward generator really does make hands with competing melds');

    diag(sprintf('deadwood: %d hands in %.2fs, %.0f a second', $checked, $took, $checked / $took));
};

done_testing();
