#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw qw(transliterate);

plan tests => 2;

my $shavian = Lingua::EN::Alphabet::Shaw->new();

is($shavian->transliterate('It ','<strong>', 'was', '</strong>', ' working!'),
    '𐑦𐑑 <strong>𐑢𐑪𐑟</strong> 𐑢𐑻𐑒𐑦𐑙!',
    "Split is in operation");
is($shavian->transliterate('He ','<em>', 'does', '</em>', ' like does.'),
    '𐑣𐑰 <em>𐑛𐑳𐑟</em> 𐑤𐑲𐑒 𐑛𐑴𐑟.',
    "Split preserves part-of-speech tagging");
