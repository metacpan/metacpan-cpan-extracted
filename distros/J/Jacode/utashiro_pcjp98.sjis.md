This file was translated to Markdown format from
ftp://ftp.oreilly.co.jp/pcjp98/utashiro/utashiro.mgp
in Shift_JIS encoding.

このファイルは
ftp://ftp.oreilly.co.jp/pcjp98/utashiro/utashiro.mgp
を Markdown 記法によって書き換えたものです。

-----
Perlによる日本語処理
PerlConference Tokyo '98 1998年11月11日、東京

# Perl による日本語処理

### (株)インターネットイニシアティブ
### 歌代 和正
### <utashiro@iij.ad.jp>

### 1998年11月11日

「PerlConference Tokyo」は原文のままです。

-----
## 日本語文字列の取り扱い

### プログラム中での表現－特殊文字との衝突

### リテラル

    # EUC だったらあまり気にしなくていい
    print "これは EUC のコードです。\n"

    # SJIS の場合は困るので here document
    $s = <<'EOT'
    「表」や「樛」という文字にはバックスラッシュが含まれる
    EOT
    # 最後に \n が入るので、不要なら取り除く
    #「樛」は原文のままです。

### 変数
変数に代入する場合はとりあえずは気にしなくてもいい
でも使うときには注意

    if (/$s/) {...

-----
## 日本語文字列の取り扱い

### 一般的な処理形式

### 内部コードは EUC が便利

* 特殊文字が含まれない
* いい加減に /[\200-\377]{2}/ でもマッチ可能
* でも補助漢字があると3バイトなのだが...
* JIS X 0201 仮名は2バイトだけど表示幅が...
* JIS や SJIS からの変換は比較的容易

### SJIS でも、内部のパターンに依存しない処理なら大差ない

### 内部コードを利用する処理の流れ

    入力を内部コードに変換
    ↓
    処理
    ↓
    外部コードに変換して出力

-----
## 日本語文字列の取り扱い

### 文字の取り扱い－多バイト文字コード

    # 文字の分割の例 (EUC)
    $_ = '日本語と英語 (English) が混在した文。';
    @chars = /[\200-\377].|./g;
    $" = '|';
    print "@chars\n";
    
    日|本|語|と|英|語| |(|E|n|g|l|i|s|h|)| |が|混|在|し|た|文|。

    # もっと真面目に作ると
    $re_euc_c    = '[\241-\376][\241-\376]';     # X0208
    $re_euc_kana = '\216[\241-\337]';            # X0201
    $re_euc_0212 = '\217[\241-\376][\241-\376]'; # X0212 補助漢字
    @chars = /$re_euc_c|$re_euc_kana|$re_euc_0212|./go;
    $" = '|';
    print "@chars\n";

-----
## 日本語文字列の取り扱い

### JIS コードの処理の例－モードの存在

### エスケープシークエンスで split してしまうと便利

    @list = split(/(\e\$B|\e\(B)/);
    for $s (@list) {
        if    ($s eq "\e\$B") {
            $japanese = 1; next;    # 日本語の始まり
        }
        elsif ($s eq "\e\(B") {
            $japanese = 0; next;    # ASCII の始まり
        }

        # 日本語だったら長さの半分、ASCII だったら長さ分を文字数として数える
        $char_count = $japanese ? length($s) / 2 : length($s);
    }

### 本当は JIS X 0208-1978,1990 も処理した方がいい

-----
## 日本語文字列の取り扱い

### 複数行に渡る文字列の検索－わかち書き問題

各文字の間に改行 (whitespace) やエスケープシークエンスが現れる「かも」しれない

### 参考: mg コマンドのデバッグ出力の例

    # EUC
    % mg -dm -j euc '文字列検索' /dev/null
    opt_p=/\312\270\s*\273\372\s*\316\363\s*\270\241\s*\272\367/

    # SJIS
    % mg -dm -j sjis '文字列検索' /dev/null
    opt_p=/\225\266\s*\216\232\s*\227\361\s*\214\237\s*\215\365/

    # JIS
    % mg -dm -j jis '文字列検索' /dev/null
    opt_p=/J8(\e\$\@|\e\$B|\e\(J|\e\(B|\s)*
    \;z(\e\$\@|\e\$B|\e\(J|\e\(B|\s)*
    Ns(\e\$\@|\e\$B|\e\(J|\e\(B|\s)*
    8\!(\e\$\@|\e\$B|\e\(J|\e\(B|\s)*\:w/

-----
## 日本語文字列の取り扱い

### タブの展開－文字列長と表示幅の違い

### 単純な例

    1 while s/\t+/' ' x (length($&) * 8 - length($`) % 8)/e;

### JIS コードを処理する例

    # 日本語文字列の表示上の幅を返す
    sub jlength {
        return(length($_[0])) unless $_[0] =~ /\033/;
        local($_) = shift;
        s/\033\$[\@B]|\033\([JB]//g;
        length;
    }
    1 while s/\t+/' ' x (length($&) * 8 - jlength($`) % 8)/e;

-----
## コード変換: 入力ファイル

JIS や SJIS は、内部コードとして扱いにくい

EUC に変換してから処理すると扱いやすい

    # 標準的なファイル入力
    open(F, $file) or die;

    # nkf でコード変換する
    open(F, "nkf -e $file|") or die;

### 問題点:
* ファイルが存在しなくてもエラーにならない
* コマンドがなくてもエラーにならない

-----
## コード変換: 出力ファイル

    # 通常のファイル出力
    open(OUT, ">$outfile") or die "$outfile: $!\n";
    while (<>) {
        print OUT $_;
    }

    # コード変換をしてファイルに出力
    open(OUT, "|nkf -j > $outfile") or die;
    ...

    # 出力ファイルがオープンできるかどうかをチェックする
    open(OUT, ">$outfile") or die "$outfile: $!\n";
    open(OUT, "|nkf -j > $outfile") or die;
    ...

-----
## コード変換: 変数の内容を変換する

    # バッククォートを使う
    $to = `echo $from | nkf -j`;
    # 問題点: シェルの特殊文字をエスケープする必要がある

    # 暗黙の fork を使う
    unless (open(IN, '-|')) {
        if (open(STDOUT, '|nkf -e')) {
            print $from;
        }
        exit;
    }
    $to = <IN>;

    # 上の例はこんな風にも書ける
    open(IN, '-|') or (open(STDOUT, '|nkf -e') and print($from), exit);
    # 本当は fork に失敗した場合も考慮する必要あり

-----
## コード変換: IPC::Open2 を利用する

    # IPC::Open2 モジュールを使う
    use IPC::Open2;
    $from = "ＥＵＣ文字列\n";
    $pid = open2(\*IN, \*OUT, 'nkf -j');
    print OUT $from;
    close OUT;
    $to = <IN>;
    close IN;

Perl4 では open2.pl

-----
## コード変換: jcode.pl

* Perl (Perl4) による日本語文字コード変換ライブラリ
* タイプグロブで文字列を渡す
* Perl5 からも変数リファレンスによって利用可能

### ポータビリティ
* jcode.pl だけあればどこでも利用可能
* 最近の jperl では利用可能 (らしい)

### 実行速度
* 小量のデータには実用的な速度だが、やはり遅い
* 大量のデータには外部コマンドを利用した方が有利

-----
## コード変換: jcode.pl

### 指定したコードに変換

    # $string の内容が JIS に変換される
    # $code には元のコードが返る
    require 'jcode.pl';
    $code = jcode::convert(\$string, "jis");

### 参照渡しの理由
* コード変換が必要ない時にはデータをコピーしたくない
* プログラミングに十分気をつければ回避は可能だが...

### 元のコードが分かっている場合

    $code = jcode::convert(\$string, "jis", "sjis");

### 値渡しによる呼び出し形式

    # 参照渡しが使いにくい場合もある
    $string =~ s/^(Subject|From|To|Cc):.*$/jcode::euc($&)/mg;

-----
## コード変換: jcode.pl

    # 入力コードの自動判定
    # コード判定インタフェース
    $code = jcode::getcode(\$line)

入力コードが指定されない場合には自動判定する

### 自動判定のアルゴリズム
* テキストにない文字があればバイナリ
* エスケープシークエンスがあれば JIS
* EUC と SJIS のパターンに対し、より多くマッチする方を選択
* 同点だったら判定不能
* どちらもなければ ASCII
* JIS X 0201 仮名 (半角仮名) は考慮されない
* 考慮すると EUC と SJIS の判定精度が大幅に下がる
* 必要な場合には、外部で判定して入力コードを指定する

-----
## コード変換: jcode.pl

JIS X 0201 仮名 ⇔ JIS X 0208 仮名

所謂、全角仮名 ⇔ 半角仮名変換

拒否反応を示す人は多いが、他に簡便な表現方法がない

### jcode::h2z_xxx, jcode::z2h_xxx
* コード毎の変換関数
* jcode::convert のオプションで指定
* 自動判定して対応する変換関数を実行
* 半角が含まれていると自動判定に失敗する可能性が高いことに注意

### jcode::convert(\$line, $ocode [, $icode [, $option]])
* z: X0201 ⇒ X0208 (半角->全角)
* h: X0208 ⇒ X0201 (全角->半角)

-----
## コード変換: jcode.pl

JIS X 0208 英数字 ⇔ ASCII

平仮名 ⇔ 片仮名

tr 関数のエミュレーション

範囲を指定する場合は、開始文字と終了文字第1バイトが同一であることが条件

    jcode::tr('Ａ-Ｚａ-ｚ０-９', 'A-Za-z0-9');
    jcode::tr('ぁ-ん', 'ァ-ン');

Perl の tr 関数はテーブルを参照して変換するので極めて高速だが、jcode::tr
は、連想配列を使って s/../../ の形に変換するのでかなり遅いことに注意

-----
