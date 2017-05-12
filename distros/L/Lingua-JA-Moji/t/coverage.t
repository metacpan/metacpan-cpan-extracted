use warnings;
use strict;
use Test::More tests => 19;
use Lingua::JA::Moji ':all';
use utf8;

eval {
    Lingua::JA::Moji::load_convertor ('guff', 'bucket');
};
ok ($@ =~ /guff2bucket/, "Test load failure message for non-existing file");
my $hyuganatsu = 'ひゅうがなつ';
my $morse = kana2morse ($hyuganatsu);
ok ($morse eq '--..- -..-- ..- .-.. .. .-. .--.',
    "Test producing morse code");
my $kana = morse2kana ($morse);
ok ($kana eq 'ヒユウガナツ');
ok (is_kana ($hyuganatsu));
ok (is_kana ($kana));
ok (! is_hiragana ($kana));
ok (is_hiragana ($hyuganatsu));
my $circled = kana2circled ($hyuganatsu, "Test kana2circled");
ok ($circled eq '㋪ュ㋒㋕゛㋤㋡');
my $round_trip = kata2hira (circled2kana ($circled));
ok ($round_trip eq $hyuganatsu, "Test circled2kana");
my $braille = kana2braille ($hyuganatsu);
ok ($braille eq '⠈⠭⠉⠐⠡⠅⠝');
my $back = braille2kana ($braille);
ok ($back eq hira2kata ($hyuganatsu));

ok (is_voiced ('が'));
ok (!is_voiced ('か'));

my @styles = romaji_vowel_styles;
ok (@styles);
ok (romaji_vowel_styles ('passport'));
ok (! romaji_vowel_styles ('nincompoop'));
my @kana_order = kana_order ();
ok (@kana_order);
my $katakana = kana2katakana ('あいうえおｱｲｳｴｵ');
ok ($katakana eq 'アイウエオアイウエオ');
my $nr = normalize_romaji ('syuutsuju');
my $nr2 = normalize_romaji ('しゅうつじゅ');
ok ($nr eq $nr2);
exit;
