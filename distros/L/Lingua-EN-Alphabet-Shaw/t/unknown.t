#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw qw(transliterate);

my $unknowns = '';

my $latn = 'My most enthusiastic contrafibulations!';
my $shaw = '𐑥𐑲 𐑥𐑴𐑕𐑑 𐑦𐑯𐑔𐑵𐑟𐑰𐑨𐑕𐑑𐑦𐑒 UNKNOWN!';

plan tests => 3;

my $shavian = Lingua::EN::Alphabet::Shaw->new();

my $handler = sub { $unknowns .= "[$_[0]]"; "UNKNOWN"; };
$shavian->unknown_handler($handler);
is($shavian->unknown_handler, $handler, "Handler is set to our handler");
is($shavian->transliterate($latn), $shaw, "Handler is called correctly");
is($unknowns, '[contrafibulations]', "Arguments to handler are correct");

