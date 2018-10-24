#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::Moji qw/kana2romaji romaji2kana/;
binmode STDOUT, ":encoding(utf8)";
my $romaji = kana2romaji ('あいうえお');
print "$romaji\n";
my $kana = romaji2kana ($romaji);
print "$kana\n";

