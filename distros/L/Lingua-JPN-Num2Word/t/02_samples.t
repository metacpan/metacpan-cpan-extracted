#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
#
# Copyright (c) PetaMem, s.r.o. 2002-present
#

use strict;
use warnings;
use utf8;

use Test::More;

# Test names contain kanji and hiragana; encode TAP handles to avoid
# "Wide character in print" from Test2::Formatter::TAP.
binmode Test::More->builder->output,         ':encoding(UTF-8)';
binmode Test::More->builder->failure_output, ':encoding(UTF-8)';
binmode Test::More->builder->todo_output,    ':encoding(UTF-8)';

my $tests;

BEGIN {
    use_ok('Lingua::JPN::Num2Word');
    $tests++;
}

use Lingua::JPN::Num2Word qw(num2jpn_cardinal num2jpn_ordinal to_string);

# ── Cardinal: kanji (default) ─────────────────────────────────────────────

my %kanji_cardinal = (
    1                       => '一',
    3                       => '三',
    10                      => '十',
    100                     => '百',
    300                     => '三百',
    600                     => '六百',
    800                     => '八百',
    1000                    => '千',
    3000                    => '三千',
    8000                    => '八千',
    1234                    => '千二百三十四',
    10_000                  => '一万',
    100_000_000             => '一億',
    1_000_000_000_000       => '一兆',
);
for my $n (sort { $a <=> $b } keys %kanji_cardinal) {
    is(num2jpn_cardinal($n), $kanji_cardinal{$n}, "cardinal kanji $n");
    $tests++;
}

# ── Cardinal: hiragana ────────────────────────────────────────────────────

my %hiragana_cardinal = (
    3    => 'さん',
    10   => 'じゅう',
    300  => 'さんびゃく',
    600  => 'ろっぴゃく',
    3000 => 'さんぜん',
    8000 => 'はっせん',
    1234 => 'せんにひゃくさんじゅうよん',
);
for my $n (sort { $a <=> $b } keys %hiragana_cardinal) {
    is(num2jpn_cardinal($n, 'hiragana'), $hiragana_cardinal{$n}, "cardinal hiragana $n");
    $tests++;
}

# ── Cardinal: romaji (canonical, with rendaku) ────────────────────────────

my %romaji_cardinal = (
    3      => 'san',
    10     => 'ju',
    300    => 'sanbyaku',
    600    => 'roppyaku',
    800    => 'happyaku',
    1000   => 'sen',
    3000   => 'sanzen',
    8000   => 'hassen',
    1234   => 'sen nihyaku sanju yon',
    10_000 => 'ichiman',
);
for my $n (sort { $a <=> $b } keys %romaji_cardinal) {
    is(num2jpn_cardinal($n, 'romaji'), $romaji_cardinal{$n}, "cardinal romaji $n");
    $tests++;
}

# ── Ordinals (kanji default, hiragana, romaji) ────────────────────────────

my %kanji_ordinal = (
    1   => '一番目',
    3   => '三番目',
    10  => '十番目',
    100 => '百番目',
);
for my $n (sort { $a <=> $b } keys %kanji_ordinal) {
    is(num2jpn_ordinal($n), $kanji_ordinal{$n}, "ordinal kanji $n");
    $tests++;
}

is(num2jpn_ordinal(3, 'hiragana'), 'さんばんめ',     'ordinal hiragana 3');  $tests++;
is(num2jpn_ordinal(3, 'romaji'),   'san-ban-me',  'ordinal romaji 3');    $tests++;
is(num2jpn_ordinal(10,'romaji'),   'ju-ban-me',   'ordinal romaji 10');   $tests++;
is(num2jpn_ordinal(123,'romaji'),  'hyaku-niju-san-ban-me', 'ordinal romaji 123'); $tests++;

# ── Capabilities ──────────────────────────────────────────────────────────

my $cap = Lingua::JPN::Num2Word::capabilities();
is($cap->{cardinal}, 1,                              'capability: cardinal'); $tests++;
is($cap->{ordinal},  1,                              'capability: ordinal');  $tests++;
is_deeply($cap->{scripts}, ['kanji','hiragana','romaji'], 'capability: scripts list'); $tests++;

# ── Legacy to_string (deprecated romaji-list interface) ───────────────────

my @parts = to_string(1234);
is(join('-', @parts), 'sen-ni-hyaku-san-ju-yon', 'to_string legacy 1234');
$tests++;
is(join('-', to_string(123)),  'hyaku-ni-ju-san',           'to_string legacy 123');
$tests++;
is(join('-', to_string(4773)), 'yon-sen-nana-hyaku-nana-ju-san', 'to_string legacy 4773');
$tests++;
is(join('-', to_string(10_000)),         'ichi-man',  'to_string legacy 10000');
$tests++;
is(join('-', to_string(1_000_000_000_000)), 'i-t-cho','to_string legacy 1 trillion');
$tests++;

done_testing($tests);

__END__
