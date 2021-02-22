use FindBin '$Bin';
use lib "$Bin";
use LJMT;is (kana2romaji ('ドッグ'), 'doggu');
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

# This kana is from https://www.amazon.co.jp/gp/product/B076WTG77B/ref=ox_sc_act_title_1?ie=UTF8&psc=1&smid=AA03GGI1A15U1

my $in = 'パーティスマスツリー';
my $amazon = kana2romaji ($in, {ve_type => 'wapuro'},);
is ($amazon, 'pa-texisumasuturi-');
my $amazon2 = kana2romaji ($in, {style => 'common', ve_type => 'none'});
is ($amazon2, 'patisumasutsuri');


TODO: {
    local $TODO = 'bugs';
};
done_testing ();

