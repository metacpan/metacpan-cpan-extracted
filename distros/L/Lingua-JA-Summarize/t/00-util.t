use strict;
use warnings;

use Test::More tests => 17;

use_ok('Lingua::JA::Summarize');

*encode = \&Lingua::JA::Summarize::_encode_ascii_word;
*decode = \&Lingua::JA::Summarize::_decode_ascii_word;
*_normalize_japanese = \&Lingua::JA::Summarize::_normalize_japanese;

is(encode('abc'), 'abc');
is(encode('Qaa'), 'Qaa');
is(encode('question'), 'question');
is(encode('abcdefghijklmnopqrstuvwxy'), 'abcdefghijklmnopqrstuvwxy');
is(decode('abc'), 'abc');
is(decode('Qaa'), 'Qaa');
is(decode('question'), 'question');
is(decode('abcdefghijklmnopqrstuvwxy'), 'abcdefghijklmnopqrstuvwxy');

ok(encode('ab0c') =~ /^qz.{9}q$/);
is(decode(encode('ab0c')), 'ab0c');
ok(encode('abcdefghijklmnopqrstuvwxyz') =~ /^qz.{9}q$/);
is(decode(encode('abcdefghijklmnopqrstuvwxyz')), 'abcdefghijklmnopqrstuvwxyz');
ok(encode("o'reilly") =~ /^qz.{9}q$/);
is(decode(encode("o'reilly")), "o'reilly");

is(_normalize_japanese("°¡À°£≥£±§À§Ë§Í°¡"), "°¡À°£≥£±§À§Ë§Í°¡");
is(_normalize_japanese("°£°¢°§°•"), "°£\n°¢°¢°£\n");
