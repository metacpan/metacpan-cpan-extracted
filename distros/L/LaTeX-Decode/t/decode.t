use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use LaTeX::Decode;

my $strA = "\\S{}\\L    \\^e\\={\\i}\\u j\\`{i}\\H u\\o\\c{S}{\\u {v}}{\\~{\\i}}";

my $resA1 = '§Łêīj̆ìűøŞ{v̆}{ĩ}';
my $resA2 = '§Łêīj̆ìűøŞv̆ĩ';

is( latex_decode($strA), $resA1, 'decode 1');
is( latex_decode($strA, strip_outer_braces => 1), $resA2, 'decode 2: strip_outer_braces');

my $strB = "\\'{\\^a}\\~{\\^a}\\~{\\u{a}}\\u{\\d{a}}\\~{\\^e}";

my $resB = "ấẫẵặễ";
is( latex_decode($strB), $resB, 'decode 2: stacked diacritics');
