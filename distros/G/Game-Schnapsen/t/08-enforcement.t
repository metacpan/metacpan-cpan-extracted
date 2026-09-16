#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(suit_of rank_of name_of);
use Game::Schnapsen::Variant qw(variants);
use Game::Schnapsen::Deal ();

# THIS FILE EXISTS BECAUSE OF TWO MUTATIONS THAT FAILED NOTHING.
#
# 1. `my $winner = $seat` - the trick always going to whoever followed - passed
#    the whole suite. t/04-trick.t tests winner_of exhaustively, but nothing
#    checked that the Deal USES it: the draw test reads the winner back out of
#    $d->last_trick->{winner}, so the probe agreed with the bug. Conservation
#    does not care either, because the card points still add to 120 whoever
#    takes them.
#
# 2. Deleting the must_follow check from apply passed too, because every other
#    test picks its card out of legal() and so never offers an illegal one.
#    legal() was correct and apply() was not, and nothing noticed.
#
# So: a second opinion about who won, computed in this file from the rules, and
# a move that legal() did not offer, pushed through apply() anyway.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
use constant MAX_TRICKS => 30;

sub settle_draw {
    my ($d) = @_;
    return unless $d->pending_draw;
    $d->apply($d->turn, { kind => 'draw' });
    return;
}

my @ASCENDING = qw(9 J Q K T A);
my %HEIGHT;
@HEIGHT{@ASCENDING} = 0 .. $#ASCENDING;

sub oracle_winner {
    my ($lead, $follow, $trump) = @_;
    my $ls = suit_of($lead);
    my $fs = suit_of($follow);
    return $HEIGHT{ rank_of($follow) } > $HEIGHT{ rank_of($lead) } ? $follow : $lead
        if $fs eq $ls;
    return $follow if $fs eq $trump;
    return $lead;
}

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

# ---- who actually took the trick --------------------------------------------------

subtest 'the deal gives each trick to the seat the rules give it to' => sub {
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@wrong, @wrong_points, $tricks, %won);
        for my $n (1 .. 30) {
            my $d = Game::Schnapsen::Deal->build(
                variant => $v, seed => seed("who $v $n"), number => $n, dealer => 'p1');

            # An independent running total, kept here and never read from the deal.
            my %mine = (p1 => 0, p2 => 0);

            my $spins = 0;
            while (!$d->over && $spins++ < MAX_TRICKS) {
                my $leader = $d->turn;
                my $lead = $d->hand_of($leader)->cards->[ $spins % $d->hand_of($leader)->count ];
                $d->apply($leader, { kind => 'lead', card => $lead });
                my $follower = $d->turn;
                my $legal = $d->legal($follower) or last;
                my $follow = $legal->[ $spins % scalar @$legal ]{card};
                $d->apply($follower, { kind => 'follow', card => $follow });
                settle_draw($d);

                my $t = $d->last_trick;
                my $best = oracle_winner($lead, $follow, $d->trump);
                my $want = $best == $lead ? $leader : $follower;

                push @wrong, sprintf('%s led %s, %s followed %s at %s: deal says %s, rules say %s',
                                     $leader, name_of($lead), $follower, name_of($follow),
                                     $d->trump, $t->{winner}, $want)
                    unless $t->{winner} eq $want;

                $mine{$want} += Game::Schnapsen::Card::points_of($lead)
                              + Game::Schnapsen::Card::points_of($follow);
                $won{ $t->{winner} }++;
                $tricks++;
            }

            for my $seat (qw(p1 p2)) {
                push @wrong_points, "$n $seat: deal " . $d->points_of($seat) . " vs $mine{$seat}"
                    unless $d->points_of($seat) == $mine{$seat};
            }
        }

        is(scalar @wrong, 0, "$v: every trick went to the right seat")
            or diag(join "\n", @wrong[0 .. ($#wrong > 3 ? 3 : $#wrong)]);

        is_deeply(\@wrong_points, [],
                  "$v: and the card points landed with the seat that took them");

        # Anti-vacuous, both ways. A sweep that played no tricks passes the
        # first; a run where one seat took everything would pass it while
        # hiding a winner that is always the follower.
        cmp_ok($tricks, '>', 200, "$v: over $tricks tricks, so the sweep meant something");
        cmp_ok(($won{p1} && $won{p2}) ? 1 : 0, '==', 1,
               "$v: and both seats won tricks (p1 " . ($won{p1} // 0)
               . ', p2 ' . ($won{p2} // 0) . ')');
    }
};

# ---- a move legal() did not offer ---------------------------------------------------

# Play until phase 2 with a position where the cascade actually bites, then hand
# apply() a card it must refuse.
sub find_refusable {
    my ($v) = @_;
    for my $n (1 .. 200) {
        my $d = Game::Schnapsen::Deal->build(
            variant => $v, seed => seed("refuse $v $n"), number => $n, dealer => 'p1');
        my $spins = 0;
        while (!$d->over && $spins++ < MAX_TRICKS) {
            my $leader = $d->turn;
            my $lead = $d->hand_of($leader)->cards->[0];
            $d->apply($leader, { kind => 'lead', card => $lead });
            my $follower = $d->turn;
            my $legal = $d->legal($follower);

            if ($d->phase == 2 && @$legal < $d->hand_of($follower)->count) {
                my %ok = map { $_->{card} => 1 } @$legal;
                my ($bad) = grep { !$ok{$_} } @{ $d->hand_of($follower)->cards };
                return ($d, $follower, $bad, $lead) if defined $bad;
            }

            last unless @$legal;
            $d->apply($follower, { kind => 'follow', card => $legal->[0]{card} });
            settle_draw($d);
        }
    }
    return ();
}

subtest 'apply refuses a follow that legal did not offer' => sub {
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($d, $seat, $bad, $lead) = find_refusable($v);
        ok(defined $bad, "$v: found a phase 2 position where the cascade bites")
            or next;

        my $before = $d->hand_of($seat)->count;
        my $out = ($d->apply($seat, { kind => 'follow', card => $bad }))[0];

        isa_ok($out, 'Game::Schnapsen::Error', "$v: following the " . name_of($bad));
        is($out->code, 'must_follow', "$v: with the code that says why");
        is($d->hand_of($seat)->count, $before, "$v: and the card is still in the hand");
        is($d->lead, $lead, "$v: with the lead still on the table");
    }
};

subtest 'a refused move changes nothing at all' => sub {
    # A refusal that half applied would leave a deal that still plays and is
    # simply wrong. Cheap to check and nothing else would.
    plan tests => 4;
    my $d = Game::Schnapsen::Deal->build(
        variant => 'schnapsen', seed => seed('nothing'), number => 1, dealer => 'p1');
    my $card = $d->hand_of('p2')->cards->[0];
    $d->apply('p2', { kind => 'lead', card => $card });

    my $tricks = scalar @{ $d->tricks };
    my $talon  = $d->talon_left;
    my $theirs = $d->hand_of('p1')->count;

    $d->apply('p1', { kind => 'follow', card => 999 });
    $d->apply('p1', { kind => 'lead', card => $d->hand_of('p1')->cards->[0] });
    $d->apply('p2', { kind => 'follow', card => $d->hand_of('p2')->cards->[0] });

    is(scalar @{ $d->tricks }, $tricks, 'no trick was recorded');
    is($d->talon_left, $talon, 'nothing was drawn');
    is($d->hand_of('p1')->count, $theirs, 'no card left the hand');
    is($d->turn, 'p1', 'and it is still their move');
};

done_testing();
