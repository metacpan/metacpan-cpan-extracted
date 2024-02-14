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

done_testing ();
