# Test calculation of Levenshtein Distance:

use strict;
use warnings;

use Test::More tests => 12;

use Lingua::Orthon;

my $orthon = Lingua::Orthon->new(match_level => 1);

my @samples = (
    [qw/BANG BARN/, 2], # synopsis example
    [qw/Bang barn/, 2], # synopsis example
    [qw/CHANCE STRAND/, 5], # Yarkoni example
    [qw/smile similes/, 2], # Yarkoni example
    [qw/pistachio hibachi/, 4], # Yarkoni example
    [qw/smile similes/, 2], # Yarkoni example
    [qw/sitting kitten/, 3], # wp: 4 identical, but initial substitution, internal substitution, terminal addition
    [qw/sunday saturday/, 3], # wp
);

my $val;

for (@samples) {
    $val = $orthon->ldist($_->[0], $_->[1]); 
    ok( $val == $_->[2], "Error in Levenshtein Distance: expected $_->[2], observed $val" );
    
    #$val = $orthon->myers_ukkonen($_->[0], $_->[1]);
    #ok( $val == $_->[2] ), "Error in Levenshtein Distance: expected $_->[2], observed $val" );
}

$val = $orthon->ldist(qw/ber BéZ/); # would be 2 if case-insensitive (substititions on index 2 and 3 only, not also 0)
ok( $val == 1, "Error in Levenshtein Distance for ignoring case and diacritics: expected 1, observed $val" );

# be case-sensitive but still ignore diacritics:

$orthon = Lingua::Orthon->new(match_level => 2);
$val = $orthon->ldist(qw/ber BéZ/); # change b to B, and r to Z, but leave the "e"s as identical
ok( $val == 2, "Error in Levenshtein Distance for ignoring diacritics but respecting case: expected 2, observed $val" );

# be case-sensitive and sensitivie to diacritics:

$orthon = Lingua::Orthon->new(match_level => 3);

$val = $orthon->ldist(qw/Bang barn/); # would be 2 if case-insensitive (substititions on index 2 and 3 only, not also 0)
ok( $val == 3, "Error in Levenshtein Distance: expected 3, observed $val" );

$val = $orthon->ldist(qw/Beng bérn/); # would be 2 if case-insensitive (substititions on index 2 and 3 only, not also 0)
ok( $val == 4, "Error in Levenshtein Distance: expected 4, observed $val" );

1;
