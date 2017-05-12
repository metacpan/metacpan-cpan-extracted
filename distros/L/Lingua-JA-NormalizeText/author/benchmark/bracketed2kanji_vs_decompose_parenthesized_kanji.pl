#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Benchmark qw/cmpthese/;
use Lingua::JA::NormalizeText qw/decompose_parenthesized_kanji nfkc/;
use Lingua::JA::Moji qw/bracketed2kanji/;

my $text = '㈱株';

cmpthese(-1, {
    'bracketed2kanji'               => sub { bracketed2kanji($text) },
    'decompose_parenthesized_kanji' => sub { decompose_parenthesized_kanji($text) },
    'nfkc'                          => sub { nfkc($text) },
});
