#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Digest::SHA ();
use Scalar::Util qw(refaddr);

use DurakFixture qw(seed32);
use Game::Durak;
use Game::Durak::Card qw(CARDS rank_of);

# Two hundred deals of random legal play, with every invariant asserted after
# every move. The choice is drawn from the seed so the whole sweep is one
# number and repeats exactly.

my $DEALS = 200;
my $LIMIT = 400;

sub pick {
    my ($tag, $n) = @_;
    return unpack('N', Digest::SHA::sha256($tag)) % $n;
}

my (@bad, $moves, $checks, $bouts, $ended, $exchanged);
my %how;

# The bout the last check saw is held, not remembered by address: a closed
# bout is freed the moment the game drops it, and the next one is allocated
# at the same address often enough that a plain refaddr map reports a cap
# that "moved" between two different bouts.
sub check {
    my ($game, $where, $seen) = @_;
    $checks++;

    my $bout  = $game->bout;
    my @open  = $bout ? $bout->cards : ();
    my $total = $game->count_of(1) + $game->count_of(2)
              + $game->talon_left + scalar(@open) + $game->discard;

    push @bad, "$where: $total cards accounted for" unless $total == CARDS;

    if ($bout) {
        my $attacks = $bout->attacks;
        my $beats   = $bout->beats;

        push @bad, "$where: more answers than attacks"
            if scalar @$beats > scalar @$attacks;

        my $unbeaten = grep { !defined $beats->[$_] } 0 .. $#$attacks;
        push @bad, "$where: $unbeaten unanswered cards outside a pile-on"
            if $unbeaten > 1 && !$bout->taken;

        push @bad, "$where: a cap of " . $bout->cap
            unless $bout->cap >= 1 && $bout->cap <= 6;

        my $last = $seen->{bout};
        if ($last && refaddr($last) == refaddr($bout)) {
            push @bad, "$where: the cap moved from $seen->{cap} to " . $bout->cap
                if $seen->{cap} != $bout->cap;
        }
        else {
            $seen->{bout} = $bout;
            $seen->{cap}  = $bout->cap;
            $bouts++;
        }

        for my $i (1 .. $#$attacks) {
            my %on_table;
            for my $j (0 .. $i - 1) {
                $on_table{ rank_of($attacks->[$j]) } = 1;
                $on_table{ rank_of($beats->[$j]) } = 1 if defined $beats->[$j];
            }
            push @bad, "$where: a rank that was not on the table"
                unless $on_table{ rank_of($attacks->[$i]) };
        }

        my %held;
        $held{$_} = 1 for @{ $game->hand_of(1) }, @{ $game->hand_of(2) };
        my @both = grep { $held{$_} } @open;
        push @bad, "$where: " . scalar(@both) . " cards in a hand and on the table"
            if @both;
    }

    # Owning the six is a pedigree and not a position: the owner may have it
    # on the table or in the heap and still be its owner, because taking your
    # own card back is not acquiring it from anybody. What may never happen is
    # the OTHER seat holding a six somebody still owns.
    my $owner = $game->six_owner;
    if (defined $owner) {
        my $six   = $game->six_of_trumps;
        my $other = 3 - $owner;
        push @bad, "$where: seat $owner owns a six that seat $other holds"
            if grep { $_ == $six } @{ $game->hand_of($other) };
    }

    push @bad, "$where: the talon grew to " . $game->talon_left
        if defined $seen->{talon} && $game->talon_left > $seen->{talon};
    $seen->{talon} = $game->talon_left;

    if ($game->over) {
        push @bad, "$where: a seat is on turn after the end" if defined $game->turn;

        my $result = $game->result;
        if (!$result) {
            push @bad, "$where: over with no result";
        }
        elsif ($result->{outcome} eq 'fool') {
            my $fool = $result->{fool};
            push @bad, "$where: the fool holds nothing"
                unless $game->count_of($fool);
            push @bad, "$where: the seat that is not the fool holds cards"
                if $game->count_of(3 - $fool);
            push @bad, "$where: the fool does not place second"
                unless $result->{places}{$fool} == 2;
        }
        elsif ($result->{outcome} eq 'draw') {
            push @bad, "$where: a draw with cards still in a hand"
                if $game->count_of(1) || $game->count_of(2);
            push @bad, "$where: a draw with a fool in it"
                if defined $result->{fool};
        }
        else {
            push @bad, "$where: an outcome of $result->{outcome}";
        }
    }
    else {
        my $turn = $game->turn;
        push @bad, "$where: nobody is on turn" unless defined $turn;
        push @bad, "$where: seat $turn is on turn"
            if defined $turn && $turn != 1 && $turn != 2;
    }

    return;
}

for my $i (1 .. $DEALS) {
    my $game = Game::Durak->build(seed => seed32("durak-invariant-$i"));
    isa_ok($game, 'Game::Durak') if $i == 1;

    my $seen = {};
    my $step = 0;
    check($game, "deal $i, the deal", $seen);

    while (!$game->over) {
        if (++$step > $LIMIT) {
            push @bad, "deal $i ran past $LIMIT moves";
            last;
        }

        my $seat  = $game->turn;
        my $legal = $game->legal($seat);
        unless (@$legal) {
            push @bad, "deal $i step $step: nothing is legal for seat $seat";
            last;
        }

        my $move = $legal->[ pick("$i:$step", scalar @$legal) ];
        my @ev = $game->apply($seat, $move);
        if (ref $ev[0] eq 'Game::Durak::Error') {
            push @bad, "deal $i step $step: " . $ev[0]->code . " for a legal move";
            last;
        }

        $moves++;
        $how{ $_->{how} }++ for grep { $_->{kind} eq 'bout_end' } @ev;
        check($game, "deal $i step $step", $seen);
    }

    my $swaps = grep { $_->{kind} eq 'swap' } @{ $game->history };
    push @bad, "deal $i held $swaps exchanges" if $swaps > 1;
    $exchanged += $swaps;

    $ended++ if $game->over;
}

is_deeply(\@bad, [], 'every invariant held in every position');
is($ended, $DEALS, 'every deal ended');
cmp_ok($checks, '>=', $DEALS * 5, "the sweep checked $checks positions");
cmp_ok($moves, '>=', $DEALS * 4, "over $moves moves");
cmp_ok($bouts, '>=', $DEALS, "across $bouts bouts");

# Reported, not bounded: how the bouts ended, so that a phase that changes the
# shape of the deal can be compared against this one.
note("bout endings: ", join ', ', map { "$_ $how{$_}" } sort keys %how);
ok(exists $how{taken}, 'bouts were taken');
ok(exists $how{exhausted}, 'and bouts ran out of legal throws');
ok(exists $how{spent}, 'and defenders ran out of cards');
cmp_ok($exchanged, '>', 0, "the trump six was exchanged $exchanged times, at most once a deal");
note('capped: ', ($how{capped} || 0),
     '. A six card attack needs six cards of ranks already on the table, '
     . 'which random play does not find; t/04-cap.t reaches it by a written bout.');

done_testing();
