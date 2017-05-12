use strict;
use warnings;
use utf8;
use Lingua::JA::Halfwidth::Katakana;
use Test::Base;
plan tests => 1 * blocks;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


run {
    my $block = shift;

    if ($block->expected) { ok($block->input =~ /\p{InHalfwidthKatakana}/); }
    else                  { ok($block->input !~ /\p{InHalfwidthKatakana}/); }
};

__DATA__
=== Halfwidth Katakana
--- input: ｦ
--- expected: 1

=== Fullwidth Hiragana
--- input: を
--- expected: 0

=== Fullwidth Katakana
--- input: ヲ
--- expected: 0

=== English alphabet
--- input: Z
--- expected: 0

=== Halfwidth Katakana and Fullwidth Katakana
--- input: アｱ
--- expected: 1

=== Halfwidth Katakana and Fullwidth Hiragana
--- input: ｧあ
--- expected: 1
