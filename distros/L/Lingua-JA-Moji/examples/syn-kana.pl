#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::Moji ':all';
binmode STDOUT, ":encoding(utf8)";
my $h = 'あいうえおがっぷぴょん';
print kata2hira ($h), "\n";
print hira2kata (kata2hira ($h)), "\n";
print kana2hw ($h), "\n";
print kata2hira (hw2katakana (kana2hw ($h))), "\n";
# Silly circled kana
print kana2circled ($h), "\n";
