use strict;
use warnings;
use Test::More tests => 2;

use utf8;

use Lingua::JA::Moji qw/hw2katakana kana2hw/;

my $full = 'アイウカキギョウ。、「」';
my $half = 'ｱｲｳｶｷｷﾞｮｳ｡､｢｣';

is( hw2katakana($half), $full );
is( kana2hw($full), $half );
