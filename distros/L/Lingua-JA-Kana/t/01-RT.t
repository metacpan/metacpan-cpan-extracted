#!perl -T
#
# $Id: 01-RT.t,v 0.1 2011/06/10 10:23:11 dankogai Exp $
#
use strict;
use warnings;
use Test::More;
use Lingua::JA::Kana;

plan tests => 2;
use utf8;
is romaji2hiragana("ryoukai"), 'りょうかい', 'RT#39590';
is romaji2hiragana("virama"),  'ゔぃらま',  'RT#45402';
