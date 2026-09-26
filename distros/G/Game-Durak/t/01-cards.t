#!perl
use strict;
use warnings;
use Test::More;

use Game::Durak::Card qw(rank_of suit_of power_of name_of long_name_of id_of
                         ids_of_suit six_of beats ranks suits CARDS);

# The pack, written out by hand rather than generated, so that this table and
# the module's arithmetic are two independent statements of the same thing.
my @PACK = qw(
    AS KS QS JS TS 9S 8S 7S 6S
    AH KH QH JH TH 9H 8H 7H 6H
    AD KD QD JD TD 9D 8D 7D 6D
    AC KC QC JC TC 9C 8C 7C 6C
);

is(CARDS, 36, 'thirty-six cards');
is(scalar @PACK, 36, 'and the written table holds thirty-six');
is_deeply([ ranks() ], [qw(A K Q J T 9 8 7 6)], 'nine ranks, ace high, six low');
is_deeply([ suits() ], [qw(S H D C)], 'four suits, spades first');

for my $id (1 .. 36) {
    my $want = $PACK[ $id - 1 ];
    is(name_of($id), $want, "id $id is $want");
    is(rank_of($id), substr($want, 0, 1), "rank of $want");
    is(suit_of($id), substr($want, 1, 1), "suit of $want");
    is(id_of($want), $id, "$want is id $id");
}

# Hand-computed: the ace is the ninth rank from the bottom, the six is the
# first, so an ace is 8 and a six is 0.
my %POWER = (A => 8, K => 7, Q => 6, J => 5, T => 4, 9 => 3, 8 => 2, 7 => 1, 6 => 0);
for my $rank (sort keys %POWER) {
    is(power_of(id_of("$rank" . 'S')), $POWER{$rank}, "power of a $rank is $POWER{$rank}");
}

is(long_name_of(id_of('AS')), 'ace of spades', 'a long name for a sentence');
is(long_name_of(id_of('TD')), 'ten of diamonds', 'a ten is spelled');
is(long_name_of(id_of('6C')), 'six of clubs', 'and so is a six');

is(id_of('as'), 1, 'id_of is case insensitive');
is(id_of('ZZ'), undef, 'id_of returns undef for a non-card');
is(id_of(undef), undef, 'id_of returns undef for undef');

is_deeply(ids_of_suit('H'), [ 10 .. 18 ], 'the hearts are ids 10 to 18');
is_deeply(ids_of_suit('C'), [ 28 .. 36 ], 'the clubs are ids 28 to 36');
is(six_of('S'), 9, 'the six of spades is id 9');
is(six_of('D'), 27, 'the six of diamonds is id 27');

for my $bad (0, 37, -1, undef, 'AS', '1.5') {
    my $shown = defined $bad ? $bad : 'undef';
    eval { rank_of($bad); 1 };
    like($@, qr/no card has id/, "rank_of dies for $shown");
}
eval { six_of('X'); 1 };
like($@, qr/no suit is/, 'six_of dies for a suit that is not a suit');
eval { beats(1, 2, 'X'); 1 };
like($@, qr/no suit is/, 'beats dies for a suit that is not a suit');

# The beating table. Every row is read off the two sentences of the rules and
# the expected answer is written here, never taken from a run:
#
#   A card which is not a trump can be beaten by playing a higher card of the
#   same suit, or by any trump. A trump card can only be beaten by playing a
#   higher trump.
#
# The label of each row is what the row is for, and the two mutation checks
# below name the labels they are expected to change.
my @VECTOR = (
    [ 'KS', 'QS', 'H', 1, 'same suit, higher' ],
    [ 'QS', 'KS', 'H', 0, 'same suit, lower' ],
    [ 'QH', 'QS', 'H', 1, 'a trump over a plain card' ],
    [ 'QS', 'QH', 'H', 0, 'a plain card under a trump' ],
    [ 'AH', 'KH', 'H', 1, 'trump over trump, higher' ],
    [ '6H', 'AH', 'H', 0, 'trump under trump, lower' ],
    [ '6H', 'AS', 'H', 1, 'the trump six over the plain ace' ],
    [ 'AS', '6H', 'H', 0, 'the plain ace under the trump six' ],
    [ 'KD', 'QS', 'H', 0, 'another plain suit, higher' ],
    [ '7D', '8C', 'H', 0, 'another plain suit, lower' ],
    [ 'AS', 'AS', 'S', 0, 'a card against itself' ],
    [ 'TS', '9S', 'D', 1, 'same suit, higher, another trump' ],
    [ '9S', 'TS', 'D', 0, 'same suit, lower, another trump' ],
    [ '6S', '7S', 'D', 0, 'the six beats nothing in its own suit' ],
    [ '7S', '6S', 'D', 1, 'but the seven beats the six' ],
    [ 'AD', 'KD', 'D', 1, 'trump ace over trump king' ],
    [ 'KD', 'AD', 'D', 0, 'trump king under trump ace' ],
    [ '6D', 'AC', 'D', 1, 'the trump six over another ace' ],
    [ 'AC', '6D', 'D', 0, 'an ace cannot answer a trump six' ],
    [ 'JH', 'TH', 'C', 1, 'jack over ten, same suit' ],
    [ 'TC', 'JH', 'C', 1, 'a low trump over a higher plain card' ],
    [ 'JH', 'TC', 'C', 0, 'a plain jack under a trump ten' ],
    [ 'QC', 'JC', 'C', 1, 'trump queen over trump jack' ],
    [ 'JC', 'QC', 'C', 0, 'trump jack under trump queen' ],
    [ 'AH', 'KD', 'C', 0, 'the ace of another plain suit' ],
    [ '6C', '6S', 'C', 1, 'the trump six over a plain six' ],
);

cmp_ok(scalar @VECTOR, '>=', 20, 'at least twenty beating vectors');

for my $v (@VECTOR) {
    my ($def, $att, $trump, $want, $why) = @$v;
    is(beats(id_of($def), id_of($att), $trump), $want,
       "$def beats $att on $trump: $want ($why)");
}

# Mutation one: the trump clause moved in front of the trump-attack clause.
# It is right about every attack made with a plain card, and it lets a low
# trump beat a high one.
sub beats_trump_first {
    my ($def, $att, $trump) = @_;
    return 0 if $def == $att;
    my $ds = suit_of($def);
    my $as = suit_of($att);
    return 1 if $ds eq $trump;
    return ($ds eq $as && power_of($def) > power_of($att)) ? 1 : 0;
}

# Mutation two: the suit comparison dropped from the last answer, so power is
# compared across unrelated plain suits.
sub beats_no_suit_check {
    my ($def, $att, $trump) = @_;
    return 0 if $def == $att;
    my $ds = suit_of($def);
    my $as = suit_of($att);
    return ($ds eq $trump && power_of($def) > power_of($att)) ? 1 : 0
        if $as eq $trump;
    return 1 if $ds eq $trump;
    return (power_of($def) > power_of($att)) ? 1 : 0;
}

sub changed_by {
    my ($mutant) = @_;
    my @changed;
    for my $v (@VECTOR) {
        my ($def, $att, $trump, $want, $why) = @$v;
        my $got = $mutant->(id_of($def), id_of($att), $trump);
        push @changed, $why if $got != $want;
    }
    return \@changed;
}

is_deeply(changed_by(\&beats_trump_first),
    [
        'trump under trump, lower',
        'trump king under trump ace',
        'trump jack under trump queen',
    ],
    'the trump-first mutation changes exactly the three lower-trump rows');

is_deeply(changed_by(\&beats_no_suit_check),
    [
        'another plain suit, higher',
        'the ace of another plain suit',
    ],
    'the dropped suit check changes exactly the two other-plain-suit rows');

done_testing();
