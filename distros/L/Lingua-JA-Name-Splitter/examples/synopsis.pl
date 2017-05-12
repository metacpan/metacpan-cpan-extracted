#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
binmode STDOUT, ":encoding(utf8)";
use Lingua::JA::Name::Splitter 'split_kanji_name';
my ($family, $given) = split_kanji_name ('風太郎');
print ("$family $given\n");

