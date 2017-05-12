#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my $wl = Games::Word::Wordlist->new(['foo', 'bar', 'baz']);
for (1..10) {
    ok($wl->is_word($wl->random_word),
       "testing checking to see if a random word from the word list is a word");
}

done_testing;
