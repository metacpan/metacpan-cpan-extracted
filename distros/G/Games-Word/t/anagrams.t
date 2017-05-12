#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my @words = qw/stop spot tops post posts stops spartan poster pot sop spa/;

my $wl = Games::Word::Wordlist->new(\@words);
my @anagrams = $wl->anagrams("stop");

is_deeply([sort @anagrams], [qw(post spot stop tops)],
          "anagrams returns the correct words");

done_testing;
