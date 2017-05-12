#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my @words = qw/foo bar baz/;
my $wl = Games::Word::Wordlist->new(\@words);
is($wl->words, 3, "created the correct number of words in the word list");
$wl->add_words(['zab', 'rab', 'oof', 'foo']);
is($wl->words, 6, "adding words results in the correct number of words");
$wl->remove_words(qw/rab foo quux/);
is($wl->words, 4, "deleting words results in the correct number of words");

done_testing;
