#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my $word_file = '';
$word_file = '/usr/dict/words' if -r '/usr/dict/words';
$word_file = '/usr/share/dict/words' if -r '/usr/share/dict/words';

SKIP: {
    skip "Can't find a system word list", 11 if $word_file eq '';

    my $wl = Games::Word::Wordlist->new($word_file, cache => 0);
    for (1..10) {
        ok($wl->is_word($wl->random_word),
           "checking to see if a random word from the word list is a word");
    }
    ok(!$wl->is_word("notaword"), "testing is_word with a non-word");
}

done_testing;
