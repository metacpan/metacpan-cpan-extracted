#! perl

use 5.006;
use strict;
use warnings;

use Lingua::EN::Syllable qw/ syllable /;
use Test::More 0.88;

my %EXPECTED_SYLLABLE_COUNT =
(
    hoopty          => 2,
    bah             => 1,
    I               => 1,
    A               => 1,
    organism        => 4,
    organisms       => 4,
    antagonisms     => 5,
    schisms         => 2,
    monisms         => 3,
    puritanisms     => 5,
    criticisms      => 4,
    microorganisms  => 6,
    surrealisms     => 4,
    isms            => 2,
    organisms       => 4,
    aphorisms       => 4,
    prisms          => 2,
    anachronisms    => 5,
    dualisms        => 4,
    euphemisms      => 4,
    mechanisms      => 4,
    mannerisms      => 4,
    yogiisms        => 4,
    metabolisms     => 5,
    baptisms        => 3,
    embolisms       => 4,
    methodisms      => 4,
    executed        => 4,
    accused         => 2,
    dosed           => 1,
    w               => 2,
    cwm             => 1,

);

plan tests => int(keys %EXPECTED_SYLLABLE_COUNT);

foreach my $word (sort keys %EXPECTED_SYLLABLE_COUNT) {
    my $syllable_count = syllable($word);
    cmp_ok($syllable_count, '==', $EXPECTED_SYLLABLE_COUNT{$word},
           "number of syllables in '$word' should be $EXPECTED_SYLLABLE_COUNT{$word}");
}
