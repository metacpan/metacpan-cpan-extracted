#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word qw(is_substring all_substrings);

my %is_substring_tests = (
    ""      => [""],
    "abc",  => ["", "abc", "ab", "ac"],
    "aaba"  => ["a", "aa", "aaa", "aab", "aba"],
    "abcba" => ["aa", "bb", "c", "abc", "cba", "abba"],
);
my %isnt_substring_tests = (
    ""      => ["a"],
    "abc"   => ["z", "ba", "baz", "abz"],
    "aaba"  => ["c", "abaa"],
);
my %all_substrings_tests = (
    ""    => [''],
    "a"   => ['', "a"],
    "ab"  => ['', "a", "b", "ab"],
    "aab" => ['', "a", "a", "b", "aa", "ab", "ab", "aab"],
    "abc" => ['', "a", "b", "c", "ab", "ac", "bc", "abc"],
);

for my $word (keys %is_substring_tests) {
    ok(is_substring($_, $word), "is '$_' a substring of '$word'?")
        for @{ $is_substring_tests{$word} };
}
for my $word (keys %isnt_substring_tests) {
    ok(!is_substring($_, $word), "is '$_' not a substring of '$word'?")
        for @{ $isnt_substring_tests{$word} };
}
for my $word (keys %all_substrings_tests) {
    is_deeply(
        [sort(all_substrings($word))],
        [sort(@{ $all_substrings_tests{$word} })],
        "do we get all of the substrings of '$word'?"
    );
}

done_testing;
