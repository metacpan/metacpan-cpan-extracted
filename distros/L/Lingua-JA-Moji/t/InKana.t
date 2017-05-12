use warnings;
use strict;
use Test::More;
use Lingua::JA::Moji 'InKana';
use utf8;

binmode STDOUT, ":utf8";
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
    ok (/^\p{InKana}+$/, "matches");
}

my @not_kana = (qw/
！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～
ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ
abcdefg
/);

for (@not_kana) {
    ok (!/\p{InKana}/, "not matches InKana");
}

unlike ('・', qr/\p{InKana}/, "katakana middle dot is not kana");

TODO: {
    local $TODO = 'bugs';

};

done_testing ();
