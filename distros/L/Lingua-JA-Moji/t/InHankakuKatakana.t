use warnings;
use strict;
use Test::More tests => 3;
use Lingua::JA::Moji qw/InHankakuKatakana/;
use utf8;
# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";
ok ('ｱ' =~ /\p{InHankakuKatakana}/, "ｱ is half-width katakana\n");
ok ('ア' !~ /\p{InHankakuKatakana}/, "ア　is not half-width katakana\n");
ok ('baby chops' !~ /\p{InHankakuKatakana}/, "baby chops is not half-width katakana\n");
