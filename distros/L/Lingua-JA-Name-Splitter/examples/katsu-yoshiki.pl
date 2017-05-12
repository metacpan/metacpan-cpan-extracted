#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::JA::Name::Splitter 'split_romaji_name';
for my $name ('KATSU, Shintaro', 'Risa Yoshiki') {
    my ($first, $last) = split_romaji_name ($name);
    print "$first $last\n";
}

