#!/usr/bin/perl
use strict;
use warnings;
use Games::Jumble;

my $jumble = Games::Jumble->new;
$jumble->set_dict('/home/doug/crossword_dict/unixdict.txt');
my @good_words = $jumble->solve_crossword('c?m?l');

if (@good_words) {
    foreach my $good_word (@good_words) {
        print "$good_word\n";
    }
} else {
    print "No words found\n";
}
