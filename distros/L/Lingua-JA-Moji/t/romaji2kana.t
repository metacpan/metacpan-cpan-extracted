use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";is (romaji2kana ("bye"), 'ビェ', "Romanization of bye as ビェ");
is (romaji2kana ('lalilulelo'), 'ァィゥェォ', "Romanization of lalilulelo is ァィゥェォ");
is (romaji2kana ('hyi'), 'ヒィ', "Romaji conversion of hyi to hixi");
is (romaji2kana ('hye'), 'ヒェ', "Romaji conversion of hye to hixe");
is (romaji2kana ('fya'), 'フャ', "Romaji conversion of fya to huxya");
is (romaji2kana ('fye'), 'フェ', "Romaji conversion of fye to huxe");
is (romaji2kana ('fyi'), 'フィ', "Romaji conversion of fyi to huxi");
is (romaji2kana ('yi'), 'イ', "Romaji conversion of yi to i");
is (romaji2kana ('fyo'), 'フョ', "Romaji conversion of fyo to huxyo");
is (romaji2kana ('fyu'), 'フュ', "Romaji conversion of fyu to huxyu");
is (romaji2kana ('dye dyi'), 'ヂェ ヂィ', "Conversion of dye, dyi");
is (romaji2kana ('mye myi'), 'ミェ ミィ', "Conversion of mye, myi");
is (romaji2kana ('gottsu'), 'ゴッツ', 'Conversion of gottsu');
is (romaji2kana ('rojji'), 'ロッジ', 'Conversion of "rojji"');

my $juyokka = 'jūyokka';
is (romaji2hiragana ($juyokka), 'じゅうよっか', "u-macron to u kana");
my $yoka = 'yōka';
is (romaji2hiragana ($yoka), 'ようか', "o-macron to u kana");

is (romaji2hiragana ('ixtsu'), 'いっ', "ixtsu to i-small tsu");
is (romaji2hiragana ('ixtu'), 'いっ', "ixtu to i-small tsu");
is (romaji2hiragana ('xwa'), 'ゎ', "xwa to small wa");
is (romaji2hiragana ('xa'), 'ぁ', "xa to small a");

done_testing ();
