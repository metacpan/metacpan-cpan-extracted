#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word qw(is_subpermutation all_subpermutations);

my %is_subpermutation_tests = (
    ""      => [""],
    "abc",  => ["", "abc", "ab", "ac", "cb", "bac", "ca"],
    "aaba"  => ["a", "aa", "aaa", "aab", "aba"],
    "abcba" => ["aa", "bb", "c", "abc", "cba", "abba", "bbaac", "caa"],
);
my %all_subpermutations_tests = (
    ""    => [""],
    "a"   => ["", "a"],
    "ab"  => ["", "a", "b", "ab", "ba"],
    "aab" => ["", "a", "a", "b", "aa", "ab", "ab", "ba", "ba", "aa",
              "aab", "aab", "aba", "aba", "baa", "baa"],
    "abc" => ["", "a", "b", "c", "ab", "ac", "bc", "ba", "ca", "cb",
              "abc", "acb", "bac", "bca", "cab", "cba"],
);

for my $word (keys %is_subpermutation_tests) {
    ok(is_subpermutation($_, $word), "is '$_' a subpermutation of '$word'?")
        for @{ $is_subpermutation_tests{$word} };
}
for my $word (keys %all_subpermutations_tests) {
    is_deeply(
        [sort(all_subpermutations($word))],
        [sort(@{ $all_subpermutations_tests{$word} })],
        "do we get all of the subpermutations of '$word'?"
    );
}

done_testing;
