#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word qw(random_permutation is_permutation);

ok( is_permutation("", ""),           "testing empty string");
ok( is_permutation("blah", "blah"),   "testing same string");
ok( is_permutation("blah", "alhb"),   "testing permuted string");
ok(!is_permutation("blah", "blh"),    "testing word with letter deleted");
ok(!is_permutation("blah", "blahs"),  "testing word with letter added");
ok(!is_permutation("blah", "blahh"),  "testing word with repeated letter");
ok( is_permutation("blaah", "hbala"), "testing word with duplicate letters");
ok(!is_permutation("blaah", "bblah"), "more duplicate letter tests");

for (1..12) {
    ok(is_permutation("blah", random_permutation("blah")), "random tests");
}

done_testing;
