#!perl
use 5.010; use strict; use warnings;
use Test::More;

use Game::Schnapsen::Card qw(rank_of suit_of power_of points_of
                             name_of long_name_of id_of ids_of_ranks
                             ranks suits CARDS);

# A card is an integer and everything else is derived, so the derivation has to
# be total and reversible. These are cheap assertions over all 24 ids rather
# than spot checks, because there are only 24 and sampling would be a choice to
# test less for no saving.

is(CARDS, 24, 'the full pack is twenty-four cards');
is_deeply([ ranks() ], [qw(A T K Q J 9)], 'six ranks, strongest first');
is_deeply([ suits() ], [qw(S H D C)], 'four suits');

# ---- total and reversible ----------------------------------------------------------

subtest 'every id derives, and every derivation reverses' => sub {
    plan tests => 5;
    my (%name, %seen, @bad_rank, @bad_suit, @bad_round);
    for my $id (1 .. CARDS) {
        my $r = rank_of($id);
        my $s = suit_of($id);
        push @bad_rank, $id unless grep { $_ eq $r } ranks();
        push @bad_suit, $id unless grep { $_ eq $s } suits();
        my $n = name_of($id);
        $name{$n}++;
        push @bad_round, "$id/$n" unless (id_of($n) // 0) == $id;
        $seen{"$r$s"}++;
    }
    is_deeply(\@bad_rank, [], 'every id gives a rank from the list');
    is_deeply(\@bad_suit, [], 'and a suit from the list');
    is(scalar keys %name, CARDS, 'every id has a name of its own');
    is_deeply(\@bad_round, [], 'and every name gives its id back');
    is(scalar keys %seen, CARDS, 'no two ids are the same rank and suit');
};

is(id_of('as'), id_of('AS'), 'a name is read case insensitively');
is(id_of('ZZ'), undef, 'a name that is not a card is undef, not a die');
is(id_of(undef), undef, 'and neither is undef');

ok(!eval { rank_of(0); 1 }, 'id 0 is not a card');
ok(!eval { rank_of(25); 1 }, 'nor is 25');
ok(!eval { rank_of('AS'); 1 }, 'nor is a name where an id belongs');

# ---- the layout ---------------------------------------------------------------------

subtest 'the pack is suit-major, six to a suit' => sub {
    plan tests => 4;
    is(name_of(1), 'AS', 'the first card is the ace of spades');
    is(name_of(6), '9S', 'the sixth is the nine of spades');
    is(name_of(7), 'AH', 'the seventh starts the hearts');
    is(name_of(CARDS), '9C', 'and the last is the nine of clubs');
};

is(long_name_of(1), 'ace of spades', 'a long name reads as a phrase');
is(long_name_of(24), 'nine of clubs', 'including the nine');

# ---- the card points ------------------------------------------------------------------

subtest 'the card point table, which both rulesets share' => sub {
    plan tests => 7;
    my %want = (A => 11, T => 10, K => 4, Q => 3, J => 2, 9 => 0);
    for my $r (ranks()) {
        is(points_of(id_of("${r}S")), $want{$r}, "a $r is worth $want{$r}");
    }

    my $total = 0;
    $total += points_of($_) for 1 .. CARDS;
    is($total, 120, 'and the whole pack is 120');
};

subtest 'both packs hold the same 120 card points' => sub {
    # THE FACT THAT MAKES ONE ID SPACE WORK. Schnapsen's pack is this pack with
    # the nines removed, and a nine is worth nothing, so removing them changes
    # how long a deal runs and not what it is worth. Sixty-Six's 130 comes from
    # the ten it pays for the last trick, not from the four extra cards.
    plan tests => 3;
    my $twenty = ids_of_ranks([qw(A T K Q J)]);
    is(scalar @$twenty, 20, 'the twenty-card pack is twenty cards');

    my $t = 0;
    $t += points_of($_) for @$twenty;
    is($t, 120, 'and is also worth 120');

    my $nines = ids_of_ranks(['9']);
    my $n = 0;
    $n += points_of($_) for @$nines;
    is($n, 0, 'because the four nines are worth nothing between them');
};

# ---- the ten above the king -------------------------------------------------------------

subtest 'the ten beats the king, which is the trap in this family' => sub {
    # Stated as a rule rather than left to fall out of the arithmetic. A ranking
    # built from the point values gets this right by luck (10 > 4); one built
    # from the ordinary sequence of a pack gets it wrong, and nothing notices
    # until somebody loses a trick they had won.
    plan tests => 4;
    my @order = map { id_of("${_}S") } ranks();
    my @powers = map { power_of($_) } @order;
    is_deeply(\@powers, [5, 4, 3, 2, 1, 0], 'power descends with the rank list');

    cmp_ok(power_of(id_of('TS')), '>', power_of(id_of('KS')), 'the ten is above the king');
    cmp_ok(power_of(id_of('AS')), '>', power_of(id_of('TS')), 'the ace is above the ten');
    cmp_ok(power_of(id_of('JS')), '>', power_of(id_of('9S')), 'and the jack above the nine');
};

subtest 'power orders within a suit and says nothing across suits' => sub {
    # A trick is decided by the suit led and the trump suit, which this module
    # knows nothing about. Equal powers across suits are correct and are what
    # stops power_of being mistaken for a card comparison.
    plan tests => 2;
    is(power_of(id_of('AS')), power_of(id_of('AC')), 'two aces have the same power');
    my %by_power;
    push @{ $by_power{ power_of($_) } }, $_ for 1 .. CARDS;
    is_deeply([ sort { $a <=> $b } map { scalar @$_ } values %by_power ],
              [ (4) x 6 ], 'and every power is held by exactly four cards');
};

# ---- the pack filter --------------------------------------------------------------------

subtest 'ids_of_ranks builds a pack' => sub {
    plan tests => 3;
    my $twenty = ids_of_ranks([qw(A T K Q J)]);
    is(scalar(grep { rank_of($_) eq '9' } @$twenty), 0, 'no nine survives the filter');
    is_deeply($twenty, [ sort { $a <=> $b } @$twenty ], 'and the pack comes back in id order');
    is(scalar @{ ids_of_ranks([qw(A T K Q J 9)]) }, CARDS, 'every rank is the whole pack');
};

done_testing();
