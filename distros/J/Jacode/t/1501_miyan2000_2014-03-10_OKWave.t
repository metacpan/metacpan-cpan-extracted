# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";
######################################################################
#
# 1501_miyan2000_2014-03-10_OKWave.t
#
# Copyright (c) 2015, 2019 INABA Hitoshi <ina@cpan.org>
#
######################################################################

sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

print "1..1\n";

if ('　' ne "\xA1\xA1") {
    print "not ok - 1 Script '$0' is not in EUC-JP.\n";
    warn "Script '$0' may be in JIS.\n"    if '　' =~ /!!/;
    warn "Script '$0' may be in SJIS.\n"   if '　' eq "\x81\x40";
    warn "Script '$0' may be in UTF-8.\n"  if '　' eq "\xE3\x80\x80";
    exit;
}

$val = '０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ（）＿＠−';
#want   0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ( ) _ @ -

Jacode::tr(*val,'０-９Ａ-Ｚａ-ｚ （）＿＠−','0-9A-Za-z ()_@-');

if ($val eq '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz()_@-') {
    print "ok - 1 $^X $0\n";
}
else {
    print "not ok - 1 $^X $0\n";
}

__END__
http://okwave.jp/qa/q8507896.html
OKWave > [技術者向] コンピューター > プログラミング > Perl
困ってます 2014-03-10 15:10:01 質問No.8507896 

[Ｑ] jcode.plのかわり

miyan2000 さん

jcode.plの
jcode::tr()
のかわりを探しています。

jcode.plの
jcode::tr($val,'０-９Ａ-Ｚａ-ｚ （）＿＠−','0-9A-Za-z ()_@-');
をPerl5.18.2で使用するとエラーが出てしまいます。これを回避したい。

プログラムがUTF-8であれば
$val =~ tr/０-９Ａ-Ｚａ-ｚ （）＿＠−/0-9A-Za-z ()_@-/;
のようにすれば実現可能みたいですが、プログラムはEUCで書かれています。
影響範囲からプログラムの文字コードをかえることはできれば避けたい。

一文字ずつ変換することも考えましたが、この方法ではパフォーマンスに懸念があります。

jacode.plなるものもありますが、これに置き換えるだけでは文字化けしてしまいました。

jcode::tr()のかわりになるような手段はあるのでしょうか？

[Ａ] inaの回答（全1件）

jacode.pl を利用して

【誤】jcode::tr($val,'０-９Ａ-Ｚａ-ｚ （）＿＠−','0-9A-Za-z ()_@-');
【正】jcode::tr(*val,'０-９Ａ-Ｚａ-ｚ （）＿＠−','0-9A-Za-z ()_@-');

で動作しました。

ちなみに jcode::tr のパフォーマンスは、jcode.pl/jacode.pl ともに
かなり遅いです。

Perlによる日本語処理 PerlConference Tokyo '98 1998年11月11日、東京
ftp://ftp.oreilly.co.jp/pcjp98/utashiro/utashiro.mgp
より引用

---------------------------------------------------------
Perl の tr 関数はテーブルを参照して変換するので
極めて高速だが、jcode::tr は、連想配列を使って s/../../
の形に変換するのでかなり遅いことに注意
---------------------------------------------------------
