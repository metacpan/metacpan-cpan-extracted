# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";
######################################################################
#
# 1502_cinquecent_2012-10-21_OKWave.t
#
# Copyright (c) 2016, 2019 INABA Hitoshi <ina@cpan.org>
#
######################################################################

sub BEGIN { eval q{ use utf8; } }
sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

print "1..2\n";

$moji = '%83%7D%83E%83X';

#                       V---------------- ここを大文字の "C" にします
#$moji =~ s/%(..)/pack("c",hex($1))/ge;
 $moji =~ s/%(..)/pack("C",hex($1))/ge;

Jacode::convert(*moji,"utf8","sjis");

if (unpack('H*',$moji) eq 'e3839ee382a6e382b9') {
    print "ok - 1 $^X $0\n";
}
else {
    print "not ok - 1 $^X $0\n";
}

if ($moji eq 'マウス') {
    print "ok - 2 $^X $0\n";
}
else {
    print "not ok - 2 $^X $0\n";
}

__END__

Perl utf8上でshiftjisをデコード
http://netricoh.okwave.jp/qa7759725.html

以下の環境にてURLエンコード（shiftjis)された文字を、UTF8として
ブラウザに表示させたいのですが、上手く表示されません。

環境：
サーバ：linux apache レンタルサーバ
※Encode.pm、Jcode.pm無し。追加モジュールインストール不可。
Perl version: 5.006001
ソースエンコード：utf-8

実行ソース：
------------------------------------
sub BEGIN { eval q{ use utf8; } }
sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

# $mojiに予めURLエンコードされた文字が格納されています。
# 例として「マウス」デコード前（%83%7D%83E%83X）とします。

# URLデコード
$moji =~ s/%(..)/pack("c",hex($1))/ge;

# デコードされたsjis文字をUTF8へコンバート
jcode::convert(\$moji,"utf8","sjis"); 

print($moji);

-----------------------------------

例のように「マウス」と言う文字が$mojiに格納されている場合、
以下のような文字化けとなってしまいます。

XXXXXXX

正常にマウスと表示させるにはどうすればよろしいのでしょうか。
アドバイスを宜しくお願いします。

投稿日時 - 2012-10-21 20:13:34

