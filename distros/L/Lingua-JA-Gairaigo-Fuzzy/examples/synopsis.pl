#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::Gairaigo::Fuzzy 'same_gairaigo';
binmode STDOUT, ":encoding(utf8)";
my $x = 'メインフレーム';
my $y = 'メーンフレーム';
if (same_gairaigo ($x, $y)) {
    print "$x and $y may be the same word.\n";
}


