#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.010000;

use Benchmark ':all';
use Lingua::JA::Regular::Unicode;
use Lingua::JA::Kana;

say "Lingua::JA::Regular::Unicode: $Lingua::JA::Regular::Unicode::VERSION";
say "Lingua::JA::Kana: $Lingua::JA::Kana::VERSION";

my $src = 'ワタシのname is ナカノでぃぃぃぃぃぃいす';

my $t = timethese(
    1000000, {
        'Lingua::JA::Kana' => sub {
            Lingua::JA::Kana::katakana2hiragana($src);
        },
        'Lingua::JA::Regular::Unicode' => sub {
            Lingua::JA::Regular::Unicode::katakana2hiragana($src)
        }
    }
);
cmpthese($t);

