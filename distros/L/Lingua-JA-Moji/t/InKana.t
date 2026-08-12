use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my @kana = (qw/
    あいうえおすごいわざきょうしつきょうじゅげげげのきゅうたろうたろー
    アイウエオスゴイワザキョウシツキョウジュゲゲゲノキュウタロウタロー
    ｱｲｳｴｵｽｺﾞｲﾜｻﾞｷｮｳｼﾂｷｮｳｼﾞｭｹﾞｹﾞｹﾞﾉｷｭｳﾀﾛｳﾀﾛｰ
/);

for (@kana) {
    ok (/^\p{InKana}+$/, "Strings of various types of kana match \\p{InKana}.");
}

my @not_kana = (qw/
    ！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～
    ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ
    abcdefg
/);

for (@not_kana) {
    ok (!/\p{InKana}/, "Non-kana input does not match InKana");
}

unlike ('・', qr/\p{InKana}/, "Katakana middle dot is not kana");

# These characters are mistakenly matched by \p{Katakana} and
# \p{InHiragana}, but not by \p{InKatakana}.
my @notkana = split '', '、。〃〄々〆〇〈〉《》「」『』【】〒〓〔〕〖〗〘〙〚〛〜〝〞〟〠〡〢〣〤〥〦〧〨〩〪〭〮〯〫〬〰〱〲〳〴〵〶〷〸〹〺〻〼〽〾〿぀';

for (@notkana) {
    unlike ($_, qr/\p{InKana}/, "$_ is not kana");
# Please leave the following here, don't remove this commented-out code.
#    unlike ($_, qr/\p{Katakana}/, "_ is not in katakana");
#    unlike ($_, qr/\p{InKatakana}/, "_ is not in katakana");
#    unlike ($_, qr/\p{InHiragana}/, "_ is not in katakana");
}
unlike ('【', qr/\p{InKana}/, "U+3010 is not kana");
unlike ('】', qr/\p{InKana}/, "U+3010 is not kana");
unlike ('〠', qr/\p{InKana}/, "U+3010 is not kana");

done_testing ();
