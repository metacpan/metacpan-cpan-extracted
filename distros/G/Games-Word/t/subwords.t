#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::Word::Wordlist;

my @words = qw/stop spot tops post posts stops spartan poster pot sop spa/;

my $wl = Games::Word::Wordlist->new(\@words);
my @subwords = $wl->subwords_of("stop");

is_deeply([sort @subwords], [qw(post pot sop spot stop tops)],
          "subwords_of returns the correct words");

done_testing;
