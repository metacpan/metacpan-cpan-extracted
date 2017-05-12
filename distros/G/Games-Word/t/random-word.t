#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my $wl = Games::Word::Wordlist->new(['foo', 'bar', 'baz', 'quux']);

my $word = $wl->random_word;
ok(defined($word), "random_word actually returned a word");
like($word, qr/^(foo|bar|baz|quux)$/,
     "testing that the word is actually in the word list");

$word = $wl->random_word(4);
is($word, 'quux', "testing random_word with a given length");

$word = $wl->random_word(3);
like($word, qr/^(foo|bar|baz)$/,
     "testing that the word was correct");

is($wl->random_word(5), undef,
   "random_word returns undef if no words are found");

my $wl2 = Games::Word::Wordlist->new([]);
is($wl2->random_word, undef,
   "random word returns undef with an empty word list");

done_testing;
