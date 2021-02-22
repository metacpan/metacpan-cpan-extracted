use FindBin '$Bin';
use lib "$Bin";
use LJMT;binmode STDOUT, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

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

TODO: {
    local $TODO = 'bugs';
};

done_testing ();
