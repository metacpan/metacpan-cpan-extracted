#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my $word_file = '';
$word_file = '/usr/dict/words' if -r '/usr/dict/words';
$word_file = '/usr/share/dict/words' if -r '/usr/share/dict/words';

SKIP: {
    skip "Can't find a system word list", 1 if $word_file eq '';

    my $wl = Games::Word::Wordlist->new($word_file);
    open my $fh, '<', $word_file or die "Couldn't open $word_file";
    for (<$fh>) {}
    is($wl->words, $., "we read in the correct number of words");
}

done_testing;
