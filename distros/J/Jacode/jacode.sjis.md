# NAME

jacode.pl - Perl program for Japanese character code conversion

# 要約

## 使用方法

```
require 'jacode.pl';
```

パッケージ名は jacode でも jcode でもどちらでも利用できます。

```
jacode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::xxx2yyy(\$line [, $option])
jacode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::jis($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::euc($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::sjis($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::utf8($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
jacode::get_inout($line)
jacode::cache()
jacode::nocache()
jacode::flushcache()
jacode::flush()
jacode::h2z_xxx(\$line)
jacode::z2h_xxx(\$line)
jacode::getcode(\$line)
jacode::getcode2(\$line [, $encoding_suggestion])
jacode::tr(\$line, $from, $to [, $option])
jacode::trans($line, $from, $to [, $option])
jacode::init()
$jacode::convf{'xxx', 'yyy'}
$jacode::z2hf{'xxx'}
$jacode::h2zf{'xxx'}
```

# 概要

この "jacode.pl" は符号化方式の変換を行うためのソフトウェアです。歌代和正さん
の作成された "jcode.pl" および "pkf" をもとにして作られており、それらのソフト
ウェアからスムーズに移行できるよう考慮されています。

Perl ライブラリとして利用すると "jcode.pl" のように、コマンドラインプログラム
として利用すると "pkf" のように機能します。コマンドラインオプションの説明は
何もオプションをつけずに実行することで参照できます。

この jacode.pl 単体で JIS、シフトJIS、EUC-JP、UTF-8 を扱うことができ、Encode
モジュールが利用できる環境であれば jacode.pl が Encode モジュールを呼び出すこ
とにより、さまざまな符号化方式の変換を行うことができます。

なお、その場合でも jcode.pl のインタフェースを使うことができるので、少ない労力
で jacode.pl に導入・移行することができます。

## 主な特徴

* jcode.pl 上位互換の機能・プログラミングインタフェース
* pkf コマンド上位互換の機能・使用方法
* Perl4 スクリプトでもあり、Perl5 スクリプトでもある
* Encode::from_to のラッパーとして機能する
* 将来に渡って利用可能なソフトウェア
* 半角カタカナをサポート
* UTF-8 から cp932 への変換は以下のテーブルを利用する

  http://unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT
  http://support.microsoft.com/kb/170559/ja
  (JIS X 0221:2007 BASIC JAPANESE and COMMON JAPANESE)

* このソフトウェアによって UTF8 フラグは隠蔽される
* インタフェースも実装方法もオブジェクト指向を利用していない
* 伝統的なプログラミング技法を利用し続けることができる

# 入手方法

西暦2018年2月の時点では、以下の URL に jacode.pl があります。

  http://search.cpan.org/dist/jacode/

ファイル "jacode.pl" を直接ダウンロードした場合は、ファイルが POD の終
了である「=cut」で終わっていることを確認してください。「=cut」で終わっ
ていない場合はそのファイルは完全ではなく、正常に動作しません。

# インストール方法

ファイルの名前を "jacode.pl" として、Perl の特殊変数  @INC に含まれるい
ずれかのフォルダに格納します。どこに置けばよいか迷った場合、アプリケー
ションプログラムと同じフォルダに配置するとよいでしょう。

# 依存しているソフトウェア

このソフトウェアは perl 4.036 もしくはそれ以降の perl で実行できます。

# サブルーチンの呼び出し方法

jacode.pl 内のサブルーチンは jacode パッケージに含まれています。また
jcode.pl との互換性を確保する目的で jcode パッケージにも含まれており、
どちらのパッケージ名でも利用できるようになっています。以下の説明では
パッケージ名を jacode としています。

# 使用している perl インタプリタが Perl5 の場合

サブルーチン名の前に jacode:: を付加します。例えば convert() の場合は

jacode::convert(...);

のようにして呼び出します。

# jcode.pl との互換性を考慮する必要がある場合

jcode.pl を利用して作成されたプログラムを保守する、などの目的で jcode.pl
のインタフェースを利用したい場合、以下のように jcode パッケージでサブルー
チンを利用することができます。

&jcode'convert(...);

# サブルーチン

## jacode::convert

任意の符号化方式に変換する

### 書式

```
jacode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
```

### 引数 \\$line

変換したい文字列をスカラー変数 $line に格納し、そのリファレンスを引数にします。
配列の要素のリファレンスやハッシュの要素のリファレンスを指定することもできま
す。このリファレンスによるインタフェースは内部的に無用なコピーを作らないこと
を目的としています。サブルーチン実行後、$line の内容は書き換わります。

### 引数 $OUTPUT_encoding

変換後の符号化方式を指定します。
このソフトウェア単体で変換できる符号化方式は以下のとおりです。

* 'jis' JISコード
* 'sjis' シフトJISコード
* 'euc' EUC-JP コード
* 'utf8' UTF-8 コード
* 'noconv' 変換を行いたくない場合

上記以外の符号化方式を指定した場合は、Encode モジュールが利用できる環境であれ
ば Encode::from_to() が呼び出されます。

### 引数 $INPUT_encoding

変換前の符号化方式を指定します。この引数は jcode.pl と互換性を保つために省略可
能となっていますが、いまや省略するべきではありません。省略時には
jacode::getcode() が内部で呼び出され、変換前の符号化方式が推測されます。この推
測は間違える場合があります。

このソフトウェア単体で変換できる符号化方式は以下のとおりです。

* 'jis' JISコード
* 'sjis' シフトJISコード
* 'euc' EUC-JP コード
* 'utf8' UTF-8 コード

上記以外の符号化方式を指定した場合は、Encode モジュールが利用できる環境であれ
ば Encode::from_to() が呼び出されます。

### 引数 $option

半角カタカナの変換時のオプションを指定します。この引数は省略可能です。

* 'z' $line に含まれる半角カタカナを全角カタカナに変換します(zenkaku)。
* 'h' $line に含まれる全角カタカナを半角カタカナに変換します(hankaku)。

### 機能

文字列を指定した符号化方式に変換する

この関数は $line に格納されている文字列を $OUTPUT_encoding で指定した符号化方式
に変換します。

### 戻り値(スカラーコンテキストの場合)

$line の変換後の符号化方式を返します。

### 戻り値(リストコンテキストの場合)

* 第1要素 変換サブルーチンへのリファレンス
* 第2要素 $line の変換後の符号化方式

### 補足説明

このサブルーチンが作成された当時、メモリは非常に貴重だったため、変換前のメモ
リと変換後のメモリは同一の領域を利用しています。変換処理が終わると変換前の文
字列はなくなります。また変換前の符号化方式は自動判定を行えるようになっている
ため、省略可能なように作成されており、そのため引数の順序が、

$OUTPUT_encoding の次に $INPUT_encoding

となっています。

## jacode::xxx2yyy

符号化方式 xxx から 符号化方式 yyy に変換する

### 書式

xxx および yyy には jis, euc, sjis, utf8 のうちいずれかが入り、全部で以下の 16
のサブルーチンがあります。

```
jacode::euc2euc(\$line [, $option])
jacode::euc2jis(\$line [, $option])
jacode::euc2sjis(\$line [, $option])
jacode::jis2jis(\$line [, $option])
jacode::jis2euc(\$line [, $option])
jacode::jis2sjis(\$line [, $option])
jacode::sjis2sjis(\$line [, $option])
jacode::sjis2euc(\$line [, $option])
jacode::sjis2jis(\$line [, $option])
jacode::utf82utf8(\$line [, $option])
jacode::utf82jis(\$line [, $option])
jacode::utf82euc(\$line [, $option])
jacode::utf82sjis(\$line [, $option])
jacode::jis2utf8(\$line [, $option])
jacode::euc2utf8(\$line [, $option])
jacode::sjis2utf8(\$line [, $option])
```

### 引数 \\$line

変換したい文字列をスカラー変数 $line に格納し、そのリファレンスを引数にします。
配列の要素のリファレンスやハッシュの要素のリファレンスを指定することもできます。
サブルーチン実行後、$line の内容は書き換わります。

### 引数 $option

半角カタカナの変換時のオプションを指定します。この引数は省略可能です。

* 'z' $line に含まれる半角カタカナを全角カタカナに変換します(zenkaku)。
* 'h' $line に含まれる全角カタカナを半角カタカナに変換します(hankaku)。

### 機能

$line に格納されている、符号化方式 xxx の文字列を符号化方式 yyy に変換します。
このサブルーチンの呼び出しによって変数 $line の内容が書き換わります。

### 戻り値

過去の実装においては、変換に成功したおおよその文字数を返す、としていたこともあ
りました。その場合、何も変換できない場合は 0 が返ります。なお、資料によっては
文字数ではなくバイト数を返す、と記述されています。

## jacode::to

符号化方式変換後の文字列を返す

### 書式

```
jacode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
```

### 引数 $OUTPUT_encoding

変換後の符号化方式を指定します。

### 引数 $line

変換したい文字列をスカラー変数 $line に格納します。

### 引数 $INPUT_encoding

変換前の符号化方式を指定します。この引数は jcode.pl と互換性を保つために省略可
能となっていますが、いまや省略するべきではありません。省略時には
jacode::getcode() が内部で呼び出され、変換前の符号化方式が推測されます。この推
測は間違える場合があります。

このソフトウェア単体で変換できる符号化方式は以下のとおりです。

* 'jis' JISコード
* 'sjis' シフトJISコード
* 'euc' EUC-JP コード
* 'utf8' UTF-8 コード

上記以外の符号化方式を指定した場合は、Encode モジュールが利用できる環境であれ
ば Encode::from_to() が呼び出されます。

### 引数 $option

半角カタカナの変換時のオプションを指定します。この引数は省略可能です。

* 'z' $line に含まれる半角カタカナを全角カタカナに変換します(zenkaku)。
* 'h' $line に含まれる全角カタカナを半角カタカナに変換します(hankaku)。

### 機能

$line で指定した文字列を $OUTPUT_encoding で指定した符号化方式に変換して返しま
す。

サブルーチン実行後、$line の内容は変化しません。

### 戻り値

符号化方式変換後の文字列です。

### 補足説明

これらの関数は、 call/return-by-value インターフェースとして簡単に使えます。
例えば s///e 演算子中で用いることができます。

## jacode::xxx

符号化方式を xxx に変換する

### 書式

xxx には jis, euc, sjis, utf8 のうちいずれかが入ります。

```
jacode::jis($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::euc($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::sjis($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
jacode::utf8($line [, $INPUT_encoding [, $option [, $INPUT_encoding_suggestion]]])
```

### 引数 $line

変換したい文字列をスカラー変数 $line に格納します。

### 引数 $INPUT_encoding

変換前の符号化方式を指定します。この引数は jcode.pl と互換性を保つために省略可
能となっていますが、いまや省略するべきではありません。省略時には
jacode::getcode() が内部で呼び出され、変換前の符号化方式が推測されます。この推
測は間違える場合があります。

このソフトウェア単体で変換できる符号化方式は以下のとおりです。

* 'jis' JISコード
* 'sjis' シフトJISコード
* 'euc' EUC-JP コード
* 'utf8' UTF-8 コード

上記以外の符号化方式を指定した場合は、Encode モジュールが利用できる環境であれ
ば Encode::from_to() が呼び出されます。

### 引数 $option

半角カタカナの変換時のオプションを指定します。この引数は省略可能です。

* 'z' $line に含まれる半角カタカナを全角カタカナに変換します(zenkaku)。
* 'h' $line に含まれる全角カタカナを半角カタカナに変換します(hankaku)。

### 機能

$line で指定した文字列を、符号化方式 $INPUT_encoding からサブルーチン名で指定
される符号化方式に変換し、その文字列を返します。

サブルーチン実行後、$line の内容は変化しません。

### 戻り値

変換後の文字列を返します。

## jacode::jis_inout

### 書式

```
jacode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
```

エスケープシーケンスの変更

### 引数 $JIS_Kanji_IN

2バイト文字へのエスケープシーケンスを指定します。

### 引数 $ASCII_IN

1バイト文字へのエスケープシーケンスを指定します。

### 機能

jacode::jis_inout() は、JIS コードで用いるエスケープシーケンスを変更し、変更
後の値を返します。$JIS_Kanji_IN には、2バイト文字へのエスケープシーケンスを、
$ASCII_IN には、１バイト文字へのエスケープシーケンスを指定します。jacode.pl は
デフォルトでは、$JIS_Kanji_IN には JIS X 0208-1983(新JIS83)の開始を示す
"1Bh 24h 42h" の 3 バイトが、$ASCII_IN には ASCII 文字の開始を示す
"1Bh 28h 42h" の 3 バイトがそれぞれ指示された状態となっています。
jacode::jis_inout() は必要に応じてこれらを変更できます。

なお、引数は省略形の 1 バイトで指定することもできます。

* ESC-$-@ JIS C 6226-1978 の場合(省略形は「@」)
* ESC-$-B JIS X 0208-1983 の場合(省略形は「B」)
* ESC-&-@-ESC-$-B JIS X 0208-1990 の場合(省略形は「&」)
* ESC-$-(-O JIS X 0213:2000 第一面の場合(省略形は「O(オー)」)
* ESC-$-(-Q JIS X 0213:2004 第一面の場合(省略形は「Q」)

### 戻り値

変更後のエスケープシーケンスのリスト ($JIS_Kanji_IN, $ASCII_IN) を返します。

## jacode::get_inout

JIS 符号化文字列から、エスケープシーケンスを取得する

### 書式

```
jacode::get_inout($line)
```

### 引数 $line

エスケープシーケンスを調べたい文字列をスカラー変数 $line に格納します。

### 機能

$line から、現在 jacode::jis_inout() によって設定されているエスケープシーケン
スのバイト列を探して、見つかればそのエスケープシーケンスを返し、見つからなけれ
ば undef を返します。

### 戻り値

jacode::jis_inout() と同様に、($JIS_Kanji_IN, $ASCII_IN) の形式です。 

* ESC-$-@ JIS C 6226-1978 の場合
* ESC-$-B JIS X 0208-1983 の場合
* ESC-&-@-ESC-$-B JIS X 0208-1990 の場合
* ESC-$-(-O JIS X 0213:2000 第一面の場合
* ESC-$-(-Q JIS X 0213:2004 第一面の場合

## jacode::h2z_xxx

半角カタカナを全角カタカナに変換

### 書式

xxx には jis, euc, sjis, utf8 のうちいずれかが入ります。

```
jacode::h2z_jis(\$line)
jacode::h2z_euc(\$line)
jacode::h2z_sjis(\$line)
jacode::h2z_utf8(\$line)
```

### 引数 \\$line

変換したい文字列をスカラー変数 $line に格納し、そのリファレンスを引数にします。
配列の要素のリファレンスやハッシュの要素のリファレンスを指定することもできます。
サブルーチン実行後、$line の内容は書き換わります。

### 機能

$line で指定した文字列に含まれる半角カタカナを全角カタカナに変換します。
xxx には符号化方式として jis, euc, sjis, utf8 のいずれかが入ります。
このサブルーチン実行後、$line の内容が書き変わります。

### 戻り値

過去の実装においては、変換に成功したおおよその文字数を返す、としていたこともあ
りました。その場合、何も変換できない場合は 0 が返ります。

## jacode::z2h_xxx

全角カタカナを半角カタカナに変換

### 書式

xxx には jis, euc, sjis, utf8 のうちいずれかが入ります。

```
jacode::z2h_jis(\$line)
jacode::z2h_euc(\$line)
jacode::z2h_sjis(\$line)
jacode::z2h_utf8(\$line)
```

### 引数 \\$line

変換したい文字列をスカラー変数 $line に格納し、そのリファレンスを引数にします。
配列の要素のリファレンスやハッシュの要素のリファレンスを指定することもできます。
サブルーチン実行後、$line の内容は書き換わります。

### 機能

$line で指定した文字列に含まれる全角カタカナを半角カタカナに変換します。
xxx には符号化方式として jis, euc, sjis, utf8 のいずれかが入ります。
このサブルーチン実行後、$line の内容が書き変わります。

### 戻り値

過去の実装においては、変換に成功したおおよその文字数を返す、としていたこともあ
りました。その場合、何も変換できない場合は 0 が返ります。

## jacode::getcode

文字列の符号化方式を推測して返す

### 書式

```
jacode::getcode(\$line)
```

符号化方式を調べる

### 引数 \\$line

符号化方式を調べたい文字列をスカラー変数 $line に格納し、そのリファレンスを引数
にします。配列の要素のリファレンスやハッシュの要素のリファレンスを指定すること
もできます。

### 機能

このサブルーチンは、$line で与えられた文字列の符号化方式を推測して返します。

### 戻り値(スカラーコンテキストの場合)

以下のうちひとつが返ります。

* 'jis' $line は JIS と推測される
* 'sjis' $line は シフトJIS と推測される
* 'euc' $line は EUC-JP と推測される
* 'utf8' $line は UTF-8 と推測される
* 'binary' $line は非文字を含む
* undef 上記のいずれでもない

### 戻り値(リストコンテキストの場合)

以下の2つの値が戻り値になります。

* 第1の要素

引数として与えられた文字列中、このサブルーチンが判断した符号化方式に該当した
バイト数(「文字数」と書かれた資料も存在するが、バイト数が正しい)

* 第2の要素

このサブルーチンが判断した符号化方式

### 例

```
#        .........1...
#        1234567890123 ←バイト数
$line = 'あいABCうえお';           # $line は EUC-JP コードとする。
$code = jacode::getcode(\$line);   # $code には、"euc" が得られる。
@code = jacode::getcode(\$line);   # @code には、(13, "euc") が得られる。
```

このサブルーチンは半角カタカナ、およびそれに相当する符号が出現した場合でも取り
除くことはなく、判定の対象とします。

jacode.pl は jcode.pl とは異なり、UTF-8 をサポートしているために
jacode::getcode() の戻り値の正確性は低くなっています。
そのため、このサブルーチンの利用はもはや推奨されていません。

## jacode::getcode2

文字列の符号化方式を推測して返す

### 書式

```
jacode::getcode2(\$line [, $encoding_suggestion])
```

符号化方式を調べる

### 引数 \\$line

符号化方式を調べたい文字列をスカラー変数 $line に格納し、そのリファレンスを引数
にします。配列の要素のリファレンスやハッシュの要素のリファレンスを指定すること
もできます。

### 機能

このサブルーチンは、$line で与えられた文字列の符号化方式を推測して返します。

### 戻り値(スカラーコンテキストの場合)

以下のうちひとつが返ります。

* 'jis' $line は JIS と推測される
* 'sjis' $line は シフトJIS と推測される
* 'euc' $line は EUC-JP と推測される
* 'utf8' $line は UTF-8 と推測される
* 'binary' $line は非文字を含む
* undef 上記のいずれでもない

### 戻り値(リストコンテキストの場合)

以下の2つの値が戻り値になります。

* 第1の要素

引数として与えられた文字列中、このサブルーチンが判断した符号化方式に該当した
バイト数(「文字数」と書かれた資料も存在するが、バイト数が正しい)

* 第2の要素

このサブルーチンが判断した符号化方式

### 例

```
#        .........1...
#        1234567890123 ←バイト数
$line = 'あいABCうえお';           # $line は EUC-JP コードとする。
$code = jacode::getcode2(\$line);   # $code には、"euc" が得られる。
@code = jacode::getcode2(\$line);   # @code には、(13, "euc") が得られる。
```

このサブルーチンは半角カタカナ、およびそれに相当する符号が出現した場合でも取り
除くことはなく、判定の対象とします。

jacode.pl は jcode.pl とは異なり、UTF-8 をサポートしているために
jacode::getcode2() の戻り値の正確性は低くなっています。
そのため、このサブルーチンの利用はもはや推奨されていません。

## jacode::cache

キャッシュを開始

### 書式

```
jacode::cache()
```

### 引数

ありません。

### 機能

jacode.pl は、演算によって符号化方式の変換を行う場合があります。一度計算した
結果はハッシュに保存され、同じ文字が出現した場合に再利用されます。通常はその
機能が ON になっているので、ON/OFF を切り替えないのであれば意識する必要はあ
りません。

### 戻り値

jacode::cache() が呼び出される前のキャッシュの ON/OFF の状態を返します。

## jacode::nocache

キャッシュの停止

### 書式

```
jacode::nocache()
```

### 引数

ありません。

### 機能

jacode.pl が用いるキャッシュを停止します。

### 戻り値

jacode::nocache() が呼び出される前のキャッシュの ON/OFF の状態を返します。

## jacode::flushcache

キャッシュの消去

### 書式

```
jacode::flushcache()
```

### 引数

ありません。

### 機能

jacode.pl のキャッシュに保存されている内容を消去します。

### 戻り値

ありません。

## jacode::flush

キャッシュの消去

### 書式

```
jacode::flush()
```

### 引数

ありません。

### 機能

内部でサブルーチン jacode::flushcache() を呼び出します。このサブルーチンは古
いドキュメントの誤りを救う目的で存在しています。

### 戻り値

ありません。

## jacode::tr

perl の tr/// 演算子の機能を模倣

### 書式

```
jacode::tr(\$line, $from, $to [,$option])
```

### 引数 \\$line

変換したい文字列をスカラー変数 $line に格納し、そのリファレンスを引数にします。
配列の要素のリファレンスやハッシュの要素のリファレンスを指定することもできます。
サブルーチン実行後、$line の内容は書き換わります。

### 引数 $from

変換したい変換前の文字を並べて記述します。

### 引数 $to

引数 $from の順に変換したい変換後の文字を並べて記述します。

### 引数 $option

'd' を指定した場合は tr///d の機能を模倣します。

### 機能

このサブルーチンは Perl の tr/// 演算子の機能を模倣します。
jcode.pl および jacode.pl は符号化方式の変換を目的としたライブラリなので
tr/// の模倣は機能的に十分ではありません。

$line の文字列中に $from に含まれている文字があれば、$to の対応する文字に置き
換えます。$line, $from, $to の符号化方式は一致させる必要があり、JIS または
EUC-JP のみが利用できます。なお、JIS X 0212(通称、補助漢字)は扱うことができま
せん。

もしシフト JIS あるいは UTF-8 の場合は、jacode::convert() によって符号化方式を
EUC-JP または JIS に変換し、その後 jacode::tr() の実行を行い、さらにその後
jacode::convert() によって元の符号化方式に戻す必要があります。

$from、および $to には "a-z" のように範囲を指定することができます。この記法は
正規表現の文字クラスに似ていますが "[a-z]" のように角かっこで囲む必要はありま
せん。"[", "]" で囲むとそれらの文字も変換対象として扱われます。

2バイト文字による範囲指定の場合、開始文字と終了文字のそれぞれの第1バイトの値
は同じである必要があります。

$option には 'd' を指定することができます。'd' を指定した場合は、$from に含ま
れていて $to に含まれていない文字が $line に出現した場合、変換後の文字列から
取り除かれます。これは tr///d の機能を模倣することを意図しています。

ハイフン「 - 」自身を置換する場合、ハイフンを範囲指定の最後に配置します。

```
$line = 'ＴＥＬ０３－９９９９－９９９９';              # 全角文字
jacode::tr(\$line, '０-９Ａ-Ｚａ-ｚ－', '0-9A-Za-z-'); # 半角に置換する例
print $line;                                           # "TEL03-9999-9999" と表示
```

### 戻り値

変換した文字の数を返します。

## jacode::trans

tr/// 演算子の機能を模倣

### 書式

```
jacode::trans($line, $from, $to [,$option])
```

### 引数 $line

変換したい文字列をスカラー変数 $line に格納し、引数にします。配列の要素のリファ
レンスやハッシュの要素のリファレンスを指定することもできます。

### 引数 $from

変換したい変換前の文字を並べて記述します。

### 引数 $to

引数 $from の順に変換したい変換後の文字を並べて記述します。

### 引数 $option

'd' を指定した場合は tr///d の機能を模倣します。

### 機能

jacode::tr() と同様に Perl の tr/// の機能を模倣します。jacode::tr() と異なり、
$line は書き変わりません。

### 戻り値

変換後の文字列を返します。

## %jacode::convf

符号化方式変換のサブルーチン jacode::xxx2yyy() のリファレンスを取得する

### 書式

```
$jacode::convf{'xxx', 'yyy'}
```

### 機能

xxx および yyy に jis, euc, sjis, utf8 のいずれかを指定すると jacode::xxx2yyy()
のサブルーチンのリファレンスを取得することができます。

## %jacode::h2zf

符号化方式変換のサブルーチン jacode::h2z_xxx() のリファレンスを取得する

### 書式

```
$jacode::h2zf{'xxx'}
```

### 機能

xxx に jis, euc, sjis, utf8 のいずれかを指定すると jacode::h2z_xxx() のサブルー
チンのリファレンスを取得することができます。

## %jacode::z2hf

符号化方式変換のサブルーチン jacode::z2h_xxx() のリファレンスを取得する

### 書式

```
$jacode::z2hf{'xxx'}
```

### 機能

xxx に jis, euc, sjis, utf8 のいずれかを指定すると jacode::z2h_xxx() のサブルー
チンのリファレンスを取得することができます。

## jacode::init

変数の初期化を行う

### 書式

```
jacode::init()
```

### 引数

ありません。

### 機能

jacode パッケージ内の変数を初期化します。jacode.pl を require 'jacode.pl';
によって利用する場合は、自動的に呼び出されます。jacode.pl の内容をアプリケー
ションプログラムの中にコピーして埋め込んだ場合は、jacode の他のサブルーチン
の呼び出しに先立って jacode::init() を実行し、内部で利用する変数を初期化する
必要があります。

### 戻り値

ありません。

# 著作者

  Copyright (c) 1992,1993,1994 Kazumasa Utashiro
  Copyright (c) 1995-2000 Kazumasa Utashiro
  Copyright (c) 2002 Kazumasa Utashiro
  Copyright (c) 2010, 2011, 2014, 2015, 2016, 2017, 2018 INABA Hitoshi

# 著作権

オリジナルの "jcode.pl" と同じ条件で利用できます。以下に引用します。

  This software is free software;
  
  Use and redistribution for ANY PURPOSE are granted as long as all
  copyright notices are retained.  Redistribution with modification
  is allowed provided that you make your modified version obviously
  distinguishable from the original one.  THIS SOFTWARE IS PROVIDED
  BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE
  DISCLAIMED.
  
  This software is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

