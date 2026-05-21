#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
#

use strict;
use warnings;
use utf8;

use Test::More;

# Test names contain Cyrillic-equivalent multibyte glyphs (Japanese kanji
# and hiragana). Encode TAP handles to avoid "Wide character in print"
# from Test2::Formatter::TAP.
binmode Test::More->builder->output,         ':encoding(UTF-8)';
binmode Test::More->builder->failure_output, ':encoding(UTF-8)';
binmode Test::More->builder->todo_output,    ':encoding(UTF-8)';

my $tests;

BEGIN {
    use_ok('Lingua::JPN::Word2Num');
    $tests++;
}

use Lingua::JPN::Word2Num qw(w2n);

# Each row: [ input, expected_value, message ]
my $cases = [
    # ── Kanji ──────────────────────────────────────────────────────────────
    [ '一',                            1,    'kanji 1' ],
    [ '三',                            3,    'kanji 3' ],
    [ '十',                           10,    'kanji 10' ],
    [ '百',                          100,    'kanji 100' ],
    [ '三百',                         300,   'kanji 300' ],
    [ '六百',                         600,   'kanji 600' ],
    [ '千',                         1000,    'kanji 1000' ],
    [ '三千',                        3000,   'kanji 3000 (RT bug guard)' ],
    [ '八千',                        8000,   'kanji 8000' ],
    [ '千二百三十四',                  1234,   'kanji 1234' ],
    [ '一万',                       10_000,  'kanji 10000' ],
    [ '一億',                  100_000_000,  'kanji 1 oku' ],
    [ '一兆',          1_000_000_000_000,    'kanji 1 cho' ],

    # ── Hiragana ──────────────────────────────────────────────────────────
    [ 'いち',                          1,    'hiragana 1' ],
    [ 'さん',                          3,    'hiragana 3' ],
    [ 'じゅう',                       10,    'hiragana 10' ],
    [ 'さんびゃく',                   300,    'hiragana 300' ],
    [ 'ろっぴゃく',                   600,    'hiragana 600' ],
    [ 'さんぜん',                    3000,    'hiragana 3000 (RT bug guard)' ],
    [ 'はっせん',                    8000,    'hiragana 8000' ],

    # ── Romaji canonical (with rendaku/gemination) ────────────────────────
    [ 'sanzen',                      3000,   'romaji sanzen' ],
    [ 'roppyaku',                     600,   'romaji roppyaku' ],
    [ 'hassen',                      8000,   'romaji hassen' ],
    [ 'happyaku',                     800,   'romaji happyaku' ],
    [ 'sanbyaku',                     300,   'romaji sanbyaku' ],
    [ 'ichiman',                  10_000,    'romaji ichiman' ],

    # ── Romaji RT-bug repros (the historical bug — all should give 3000) ──
    [ 'san zen',                     3000,   'RT bug: san zen' ],
    [ 'san-zen',                     3000,   'RT bug: san-zen' ],
    [ 'san sen',                     3000,   'RT bug: san sen (legacy un-rendaku)' ],

    # ── Romaji legacy un-rendaku forms ────────────────────────────────────
    [ 'roku hyaku',                   600,   'legacy: roku hyaku' ],
    [ 'hachi sen',                   8000,   'legacy: hachi sen' ],
    [ 'yon-sen-nana-hyaku-nana-ju-san', 4773, '4773 hyphenated legacy' ],

    # ── Invalid input ─────────────────────────────────────────────────────
    [ 'this is not valid number in Japan', undef, 'invalid number returns undef' ],
    [ undef,                       undef,    'undef arg returns undef' ],
];

for my $case (@{$cases}) {
    my ($input, $expected, $msg) = @{$case};
    my $got = w2n($input);
    is($got, $expected, $msg);
    $tests++;
}

done_testing($tests);

__END__
