use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);

use Game::Senet::Sticks qw(throw_for roll_for);

=pod

THIS IS THE FILE THAT FAILS WHEN THE STICKS CHANGE.

Every other test of the sticks asks whether they are fair, and a different set
of fair sticks passes all of them. Counting dark faces instead of light ones is
such a set: the weights 1, 4, 6, 4, 1 read the same backwards. This file asks
whether they are THESE sticks: the throws below were generated once, on 17
October 2026, read, and written down.

A change that reddens this file changes what every seed throws. Every game
ever recorded with a seed then replays to a different game, and a site that
stores games by seed can no longer show one of them. Do not regenerate these
strings to make the file pass. If the sticks must change, that is a decision
about every stored game and is taken first.

=cut

my %PINNED = (
    'senet pinned one' => {
        sticks => '1100 0110 1010 0001 0110 0010 0101 0010 1011 0000 1101 1100 1100 0111 0001 1000 '
                . '0100 1001 1110 1101 0010 1001 1000 1110 1000 0011 0111 1111 0011 1100 1010 1111 '
                . '1000 0111 0110 1011 0011 1010 1010 1011 0100 1101 1011 0010 0111 0010 1001 0111 '
                . '0100 1101 1011 1101 0111 1100 1100 0001 1111 1011 0010 0100 0110 0001 1010 0100',
        rolls  => '13956e4e7fc8c3053f1883b48fb993355d4897b2fe195c62ece5fd106f2409f5',
    },
    "senet pinned two\x00\xff" => {
        sticks => '0101 1011 0001 1100 1101 0010 1111 1000 1010 1001 0001 1011 1111 0001 1100 0111 '
                . '0111 1100 0100 0000 1100 1010 1010 0011 0101 0110 1011 1001 1011 1011 1100 1110 '
                . '0111 1100 1100 1001 1101 1010 1111 0111 1000 0111 0010 1010 0111 1000 0100 1110 '
                . '1111 0110 1111 0011 0101 0101 1110 1000 0010 0010 1000 0110 0011 1101 0101 1110',
        rolls  => '3f8ad39df3052a931010ea6b61a57eca3c7ceed4ccb0f042a9840b8e33ff506d',
    },
);

for my $seed (sort keys %PINNED) {
    (my $shown = $seed) =~ s/([^ -~])/sprintf '\\x%02x', ord $1/ge;
    my $got = join ' ', map { join '', @{ throw_for($seed, $_) } } 0 .. 63;
    is($got, $PINNED{$seed}{sticks}, "the first 64 throws of '$shown', stick by stick");
    is(sha256_hex(join '', map { roll_for($seed, $_) } 0 .. 9_999), $PINNED{$seed}{rolls},
        "and a digest of its first 10,000 rolls");
}

done_testing();
