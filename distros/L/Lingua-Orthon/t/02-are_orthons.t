# Test calc of Coltheart Boolean (are_orthons):

use strict;
use warnings;

use Test::More tests => 13;
use Lingua::Orthon;

my $orthon = Lingua::Orthon->new(match_level => 1);

my @samples = (
    [qw/b B/, 0], # same char, so identical, and so aren't "neighbours"
    [qw/be Be/, 0], # still not neighbours, just char-identical at this match-level
    [qw/be Ba/, 1], # clearly neighbours: miss by 1, setting aside the case difference
    [qw/BANG BAND/, 1],
    [qw/BANG BRANG/, 0],
    [qw/BANG BANG/, 0],
    [qw/brInG BRiNe/, 1], # only 1 substitution G => e, 'r' and 'R' are equal, and 'I' and 'i' are equal
);

my ($val, @words) = ();

for (@samples) {
    $val = $orthon->are_orthons($_->[0], $_->[1]); 
    ok( $val == $_->[2], "Error in Coltheart bool (are_orthons) for '$_->[0]' and '$_->[1]': expected $_->[2] observed $val" );
}

# be case-sensitive:

#$orthon = Lingua::Orthon->new(match_level => 3);
$orthon->set_eq(match_level => 3);

# If are_orthons
@samples = (
    [qw/b B/, 1],  # diff char, non-identical, and so are "neighbours"
    [qw/be Ba/, 0], # not neighbours: miss by 1 alphabetical char, but also by a case-variant char
    [qw/BANG BAND/, 1],
    [qw/BANG BRANG/, 0],
    [qw/BANG BANG/, 0],
    [qw/brInG BRiNe/, 0], # more than 1 substitution
);

for (@samples) {
    $val = $orthon->are_orthons($_->[0], $_->[1]); 
    ok( $val == $_->[2], "Error in Coltheart bool (are_orthons) for '$_->[0]' and '$_->[1]': expected $_->[2] observed $val" );
}

1;