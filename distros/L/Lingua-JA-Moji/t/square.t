use warnings;
use strict;
use Test::More;
use Lingua::JA::Moji qw/square2katakana katakana2square/;
use utf8;
is (square2katakana ('㌆'), 'ウォン', "square2katakana test"); 
is (katakana2square ('アイウエオウォン'), 'アイウエオ㌆', "katakana2square test");
done_testing ();
exit;
