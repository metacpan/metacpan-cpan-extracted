#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Backgammon::Shots qw(shots_at);

# The published shot table, as a TEST of the enumeration rather than as its
# source. These are the numbers every backgammon book prints; if the code
# and the book disagree, the code is wrong.
my %published = (
    1 => 11, 2 => 12, 3 => 14, 4 => 15, 5 => 15, 6 => 17,
    7 => 6,  8 => 6,  9 => 5,  10 => 3, 11 => 2, 12 => 3,
    15 => 1, 16 => 1, 18 => 1, 20 => 1, 24 => 1,
);

plan tests => scalar(keys %published) + 5;

for my $d (sort { $a <=> $b } keys %published) {
    is(shots_at($d), $published{$d}, "$d away is $published{$d} shots in 36");
}

# the distances no roll can reach at all
is(shots_at($_), 0, "$_ away cannot be hit") for 13, 14, 17;

is(shots_at(0), 0, 'nothing is zero away');
is(shots_at(25), 0, 'and nothing is further than the board');

done_testing();
