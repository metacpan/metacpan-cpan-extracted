use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);

use Game::RoyalUr::Dice qw(throw_for roll_for);

=pod

THIS IS THE FILE THAT FAILS WHEN THE DICE CHANGE.

Every other test of the dice asks whether they are fair, and a different set
of fair dice passes all of them. This one asks whether they are THESE dice:
the throws below were generated once, on 9 October 2026, read, and written
down.

A change that reddens this file changes what every seed throws. Every game
ever recorded with a seed then replays to a different game, and a site that
stores games by seed can no longer show one of them. Do not regenerate these
strings to make the file pass. If the dice must change, that is a decision
about every stored game and is taken first.

=cut

my %PINNED = (
    'royalur pinned one' => {
        4 => '1100 1101 0010 1010 0100 1010 0110 1001 1010 0100 0000 0011 0001 1011 1001 1001 '
           . '0110 0111 0000 0010 0001 1011 1101 0001 0101 1100 0000 0110 1000 0111 0110 0110 '
           . '0011 1110 1001 1101 0011 0010 1111 0010 1011 1001 0111 0111 0011 0000 1011 1011 '
           . '1000 0000 0111 0001 0110 1100 1111 0010 1110 0111 1100 1111 0000 0100 1111 0011',
        3 => '110 110 001 101 010 101 011 100 101 010 000 001 000 101 100 100 '
           . '011 011 000 001 000 101 110 000 010 110 000 011 100 011 011 011 '
           . '001 111 100 110 001 001 111 001 101 100 011 011 001 000 101 101 '
           . '100 000 011 000 011 110 111 001 111 011 110 111 000 010 111 001',
        finkel  => '9dc731e8ed5089fbabd2d47d93b203f3f44b5b56856b14bef1b2f1c76c6af4a2',
        masters => 'f148cab10852b070e6c0f77a6f859064983af771a91fe3be7d8cce9825592ba5',
    },
    "royalur pinned two\x00\xff" => {
        4 => '1111 1111 0010 0110 1110 0011 1010 1100 1110 0011 1010 0110 1011 0000 1010 0000 '
           . '1111 1010 1001 0110 0001 1110 1101 1101 0000 1001 1000 0100 0100 1100 1001 0011 '
           . '0110 1000 1011 1101 0111 1111 0000 1101 0001 1100 0011 1000 0110 0101 0111 1110 '
           . '0011 1110 0000 0100 0000 0011 0101 0000 1010 0011 0111 1111 1000 0011 0100 0110',
        3 => '111 111 001 011 111 001 101 110 111 001 101 011 101 000 101 000 '
           . '111 101 100 011 000 111 110 110 000 100 100 010 010 110 100 001 '
           . '011 100 101 110 011 111 000 110 000 110 001 100 011 010 011 111 '
           . '001 111 000 010 000 001 010 000 101 001 011 111 100 001 010 011',
        finkel  => '14f047a445472b02eba389f8bd3991b5aeb603d468abd09210e38cc329e53144',
        masters => '203858f8b2b302279a3d21b49a23e65b85c15858b30884964528bcdc7ece0151',
    },
);

my %RULES = (
    finkel  => { dice => 4, zero_rolls => 0 },
    masters => { dice => 3, zero_rolls => 4 },
);

for my $seed (sort keys %PINNED) {
    (my $shown = $seed) =~ s/([^ -~])/sprintf '\\x%02x', ord $1/ge;
    for my $dice (4, 3) {
        my $got = join ' ', map { join '', @{ throw_for($seed, $_, $dice) } } 0 .. 63;
        is($got, $PINNED{$seed}{$dice}, "'$shown': the first sixty-four throws of $dice dice");
    }
    for my $set (sort keys %RULES) {
        my $rolls = join '', map { roll_for($seed, $_, $RULES{$set}) } 0 .. 9_999;
        is(length $rolls, 10_000, "'$shown': ten thousand rolls under $set, a digit each");
        is(sha256_hex($rolls), $PINNED{$seed}{$set}, 'and they are the ten thousand written down');
    }
}

done_testing();
