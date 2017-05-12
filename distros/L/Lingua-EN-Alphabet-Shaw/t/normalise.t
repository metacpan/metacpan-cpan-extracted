#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw;

my @tests = (
    '𐑲 𐑤𐑳𐑝 𐑘𐑵' => '𐑲 𐑤𐑳𐑝 𐑿', 'test YEW',
    '𐑢𐑰 𐑨𐑮 𐑢𐑳𐑯' => '𐑢𐑰 𐑸 𐑢𐑳𐑯', 'test OR',
    '𐑪𐑮 𐑯𐑪𐑑' => '𐑹 𐑯𐑪𐑑', 'test ARE',
    '𐑖𐑱𐑝𐑦𐑩𐑯 𐑮𐑪𐑒𐑕' => '𐑖𐑱𐑝𐑾𐑯 𐑮𐑪𐑒𐑕', 'test IAN',
    '𐑞 𐑧𐑮 𐑦𐑟 𐑒𐑤𐑦𐑮' => '𐑞 𐑺 𐑦𐑟 𐑒𐑤𐑽', 'test AIR and EAR',
    '𐑚𐑳𐑮𐑛𐑟 𐑓𐑤𐑲' => '𐑚𐑻𐑛𐑟 𐑓𐑤𐑲', 'test ERR',
    '𐑚𐑫𐑗𐑩𐑮 𐑚𐑱𐑒𐑩𐑮' => '𐑚𐑫𐑗𐑼 𐑚𐑱𐑒𐑼', 'test ARRAY',
);
plan tests => scalar(@tests)/3;

my $shavian = Lingua::EN::Alphabet::Shaw->new();

while (@tests) {
    my $unnormalised = shift @tests;
    my $normalised = shift @tests;
    my $description = shift @tests;

    is ($shavian->normalise($unnormalised), $normalised, $description);
}
