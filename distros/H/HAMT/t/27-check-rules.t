#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;
use HAMT::Vector;

# The checkers' rules, each tried on a structure broken that one way. A
# checker that cannot see what it claims to see is a test that lies, so
# each rule gets a trie or a vector built by hand in C with exactly that
# wrong, and the number the checker gives back is the rule's.

my $blocks = HAMT::_live_blocks();

is(HAMT::_map_broken(0), 0, 'the trie as built passes');
my %map = (
    1  => [1,  'a node with a count of zero'],
    2  => [2,  'a position in both maps'],
    3  => [3,  'a node holding nothing'],
    4  => [4,  'one entry and no children, below the root'],
    5  => [5,  'a collision node above depth twelve'],
    6  => [6,  'a collision node with a map bit set'],
    7  => [7,  'a collision node with one entry'],
    8  => [8,  'two equal keys in a collision node'],
    9  => [9,  'an indexing node at depth twelve'],
    10 => [10, 'an entry not where its hash puts it'],
    12 => [12, 'entries that do not total the count'],
    13 => [13, 'an entry out of order'],
    21 => [1,  'an entry with a count of zero'],
    22 => [1,  'an entry with a count of zero in a collision node'],
    23 => [11, 'an entry slot holding nothing'],
    24 => [11, 'a collision slot holding nothing'],
    25 => [11, 'a child slot holding nothing'],
    26 => [10, 'a collision entry not where its hash puts it'],
);
for my $what (sort { $a <=> $b } keys %map) {
    is(HAMT::_map_broken($what), $map{$what}[0], "map rule $map{$what}[0]: $map{$what}[1]");
}

is(HAMT::_vec_broken(0), 0, 'the vector as built passes');
my %vec = (
    1  => [1,  'a count with no tail'],
    2  => [2,  'a tail that is not a leaf'],
    3  => [2,  'a tail holding nothing'],
    4  => [2,  'a tail holding more than the count'],
    5  => [14, 'a tail with a table'],
    6  => [5,  'a tail with a count of zero'],
    7  => [11, 'a tail slot holding nothing'],
    8  => [3,  'a root where there should be none'],
    9  => [3,  'no root where there should be one'],
    10 => [4,  'a shift that is not a multiple of five'],
    11 => [9,  'a root with one child above the lowest level'],
    12 => [11, 'a child slot holding nothing'],
    13 => [5,  'a node with a count of zero'],
    14 => [6,  'a node holding nothing'],
    15 => [7,  'a leaf where a node belongs'],
    16 => [14, 'a leaf with a table'],
    17 => [11, 'a leaf slot holding nothing'],
    18 => [8,  'a regular node whose first child is not full'],
    19 => [13, 'a relaxed node with children to spare, when none are allowed'],
    20 => [12, 'a table that does not say what is under the node'],
);
for my $what (sort { $a <=> $b } keys %vec) {
    is(HAMT::_vec_broken($what), $vec{$what}[0], "vector rule $vec{$what}[0]: $vec{$what}[1]");
}

is(HAMT::_live_blocks(), $blocks, 'and every structure built for this was freed');

done_testing;
