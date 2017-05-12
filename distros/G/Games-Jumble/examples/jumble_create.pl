#!/usr/bin/perl
use strict;
use warnings;
use Games::Jumble;

my $jumble = Games::Jumble->new;
$jumble->set_num_words(6);
$jumble->set_word_lengths_allowed(5,6);
$jumble->set_word_lengths_not_allowed(3);
$jumble->set_dict('/home/doug/crossword_dict/unixdict.txt');

my @jumble = $jumble->create_jumble;

foreach my $word (@jumble) {
    print "$word\n";
}
