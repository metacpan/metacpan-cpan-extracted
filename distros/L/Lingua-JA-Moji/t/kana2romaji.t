use warnings;
use strict;
use Test::More;
use Lingua::JA::Moji qw/kana2romaji romaji2kana/;
use utf8;
is (kana2romaji ('ドッグ'), 'doggu');
# Common
is (kana2romaji ('ジェット', {style => 'common'}), 'jetto');
is (kana2romaji ('ウェ', {style => 'common'}), 'we');
my $week;
is ($week = kana2romaji ('ウィーク', {style => 'common'}), 'wiiku', "$week");
like ($week = kana2romaji ('ゴールデン ウィーク', {style => 'common'}), qr/wiiku/);
unlike (kana2romaji ('アンニュイ'), qr/n'n/, "don't add useless apostrophe");

my $towa = 'トヮ';
my $towar = kana2romaji ($towa);
is ($towar, 'toxwa');
my $towark = romaji2kana ($towar);
is ($towark, $towa);

TODO: {
    local $TODO = 'bugs';
};
done_testing ();

