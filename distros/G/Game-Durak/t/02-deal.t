#!perl
use strict;
use warnings;
use Test::More;

use Game::Durak::Card qw(id_of name_of suit_of power_of);
use Game::Durak::Deck qw(order_for deal_for first_attacker HAND_SIZE SEATS);

sub seed { return sprintf '%-32.32s', $_[0] }

is(length seed('durak'), 32, 'the test seeds are 32 bytes');
is(HAND_SIZE, 6, 'six cards a hand');
is(SEATS, 2, 'two seats');

my $order = order_for(seed('durak-one'), 1);
is(scalar @$order, 36, 'the order holds thirty-six ids');
is_deeply([ sort { $a <=> $b } @$order ], [ 1 .. 36 ], 'and it is a permutation');
is_deeply(order_for(seed('durak-one'), 1), $order, 'the same seed gives the same order');
isnt(join('-', @{ order_for(seed('durak-two'), 1) }), join('-', @$order),
     'a different seed gives a different order');
isnt(join('-', @{ order_for(seed('durak-one'), 2) }), join('-', @$order),
     'a different deal number gives a different order');

for my $bad ([ 'short', 1 ], [ seed('durak'), 0 ], [ seed('durak'), 'x' ]) {
    eval { order_for(@$bad); 1 };
    ok($@, 'order_for dies for a bad seed or deal number');
}

my $deal = deal_for(seed('durak-one'), 1);

is(scalar @{ $deal->{hands}{1} }, 6, 'seat one holds six');
is(scalar @{ $deal->{hands}{2} }, 6, 'seat two holds six');
is_deeply($deal->{hands}{1}, [ sort { $a <=> $b } @{ $deal->{hands}{1} } ],
          'a hand comes back sorted');

# Dealt singly, seat one first: the source says "one at a time, clockwise".
is_deeply($deal->{hands}{1}, [ sort { $a <=> $b } @{$order}[ 0, 2, 4, 6, 8, 10 ] ],
          'seat one has the odd positions of the order');
is_deeply($deal->{hands}{2}, [ sort { $a <=> $b } @{$order}[ 1, 3, 5, 7, 9, 11 ] ],
          'seat two has the even ones');

is($deal->{trump_card}, $order->[12], 'the turn-up is the card after the deal');
is($deal->{trump}, suit_of($deal->{trump_card}), 'the trump is its suit');

# The turn-up stays in the talon and is drawn last. Twelve cards dealt, one
# turned up, twenty-three left face down: 12 + 1 + 23 == 36, so the talon is
# twenty-four and not twenty-three.
is(12 + 1 + 23, 36, 'the pack accounts for itself');
is(scalar @{ $deal->{talon} }, 36 - 12, 'the talon holds twenty-four');
is(scalar @{ $deal->{talon} }, 24, 'which is twenty-four');
is($deal->{talon}[-1], $deal->{trump_card}, 'and the turn-up is its last card');
is_deeply([ @{ $deal->{talon} }[ 0 .. 22 ] ], [ @{$order}[ 13 .. 35 ] ],
          'the face down cards keep the order they were shuffled into');

my %seen;
$seen{$_}++ for @{ $deal->{hands}{1} }, @{ $deal->{hands}{2} }, @{ $deal->{talon} };
is(scalar keys %seen, 36, 'every card is somewhere');
is_deeply([ grep { $seen{$_} != 1 } sort { $a <=> $b } keys %seen ], [],
          'and nothing is anywhere twice');

is_deeply(deal_for(seed('durak-one'), 1), $deal, 'the deal is a pure function of its inputs');

eval { deal_for(seed('durak-one'), 1, 3); 1 };
like($@, qr/two seats/, 'three seats is a different game and this one says so');

# first_attacker, on hands written here and answered by hand.
my @WHO = (
    {
        why   => 'the trump six opens',
        trump => 'H',
        hands => { 1 => [ map { id_of($_) } qw(AS KS QD JC TC 9D) ],
                   2 => [ map { id_of($_) } qw(6H AH KD QC JS 8C) ] },
        want  => 2,
    },
    {
        why   => 'with no six, the seven does',
        trump => 'H',
        hands => { 1 => [ map { id_of($_) } qw(7H AS KS QD JC TC) ],
                   2 => [ map { id_of($_) } qw(9H AH KD QC JS 8C) ] },
        want  => 1,
    },
    {
        why   => 'every trump in one hand',
        trump => 'D',
        hands => { 1 => [ map { id_of($_) } qw(AS KS QS JS TS 9S) ],
                   2 => [ map { id_of($_) } qw(AD KD QD JD TD 9D) ] },
        want  => 2,
    },
    {
        why   => 'no trump in either hand falls back to the lowest seat',
        trump => 'C',
        hands => { 1 => [ map { id_of($_) } qw(AS KS QS JS TS 9S) ],
                   2 => [ map { id_of($_) } qw(AD KD QD JD TD 9D) ] },
        want  => 1,
    },
    {
        why   => 'the lowest trump wins, not the highest',
        trump => 'S',
        hands => { 1 => [ map { id_of($_) } qw(8S AH KH QH JH TH) ],
                   2 => [ map { id_of($_) } qw(AS KS QS JS TS 9S) ] },
        want  => 1,
    },
);

for my $case (@WHO) {
    is(first_attacker($case->{hands}, $case->{trump}), $case->{want}, $case->{why});
}

eval { first_attacker($WHO[0]{hands}, 'X'); 1 };
like($@, qr/wants a suit/, 'first_attacker dies rather than answering seat one');

# A deal where neither hand holds a trump is legal and rare (about one in
# fifty), so it is searched for rather than pinned: a seed chosen in advance
# is a seed chosen by running the code.
my ($found, $tried);
for my $i (1 .. 2000) {
    $tried = $i;
    my $d = deal_for(sprintf('durak%027d', $i), 1);
    my @trumps = grep { suit_of($_) eq $d->{trump} }
                 @{ $d->{hands}{1} }, @{ $d->{hands}{2} };
    next if @trumps;
    $found = $d;
    last;
}
ok($found, "a trumpless deal was found in $tried seeds");
is($found->{first}, 1, 'and its opener is seat one, by the fallback') if $found;

# The opener really does hold the lowest trump in the dealt cards.
my (@wrong, $checked);
for my $i (1 .. 200) {
    my $d = deal_for(sprintf('durak%027d', $i), 1);
    my @trumps = sort { power_of($a) <=> power_of($b) }
                 grep { suit_of($_) eq $d->{trump} }
                 @{ $d->{hands}{1} }, @{ $d->{hands}{2} };
    next unless @trumps;
    $checked++;
    my $low  = $trumps[0];
    my $seat = (grep { $_ == $low } @{ $d->{hands}{1} }) ? 1 : 2;
    next if $d->{first} == $seat;
    push @wrong, "deal $i opens seat $d->{first}, lowest trump "
                 . name_of($low) . " is in seat $seat";
}
cmp_ok($checked, '>=', 190, 'nearly every deal put a trump in a hand');
is_deeply(\@wrong, [], "the lowest dealt trump opens, over $checked deals");

done_testing();
