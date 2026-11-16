# IO::Polarizer 設計

> **名前について（2026-11-16）**: リリースの前に、名前を IO::Factotum に変えた。
> factotum は「頼まれた仕事を何でも引き受ける人」。この文書は、設計したときの
> 名前（IO::Polarizer、`--polarizer`）のまま残してある。読むときは
> Polarizer を Factotum、`--polarizer` を `--factotum` に読み替える。

2026-11-16

## 目的

`nup *.c` のようにファイルを渡しただけで、ソースにシンタックスハイライトが
付くようにする。いまは `nup less foo.c` と打てば less の LESSOPEN で色が付くが、
毎回 less を書き足すのは面倒。

そのための部品として、ファイルを読むときに変換をはさむ汎用のモジュール
IO::Polarizer を作る。偏光フィルターのように、元のファイルは変えずに、通して
読むときにだけ見え方を変える。

## ゴール

1. `nup *.c` で、skylighting が入っていれば、各ファイルに色が付く。
2. ファイル名の見出し（nup の `--filename`、既定で有効）には元のファイル名が出る。
   一時ファイルの名前（`/dev/fd/5` など）は出ない。
3. 複数のファイルを渡したとき、ファイルごとに変換される。
4. IO::Polarizer は ansicolumn 専用ではなく、ほかのプログラム（ansifold、greple
   など）からも使える汎用のモジュールにする。

## ゴールでないもの

- mdee の Markdown のコードブロックへのハイライト。後で別に検討する
  （md モジュールの `code_blocks` の処理で skylighting を呼ぶ方向）。
- optex textconv を IO::Polarizer に乗せること。将来の候補（そうすれば
  `--textconv` の見出しが `/dev/fd/N` になる問題も直る）だが、今回はしない。
- ansifold、greple を IO::Polarizer に対応させること。

## してはいけないこと

- 元のファイルを書き換える。
- skylighting が入っていない環境で、nup の動きや出力が変わる。
- 変換に失敗したファイルが空になったり、表示されなくなったりする。
  失敗したら、元のファイルをそのまま読む。
- 見出しに一時ファイルの名前が出る。

## 調べて分かっていること

- **ansicolumn がファイルを読むのは 1 か所だけ**：
  `ANSI-Tools/App-ansicolumn/lib/App/ansicolumn.pm` の `read_files`（394 行目）。
  ファイルごとに `open my $fh, $file` で開き、`App::ansicolumn::Document` に
  `name => $file` と中身を入れている。見出しはこの `name` から作られる。
- **いまの textconv は引数を一時ファイルに置き換える**：
  `App::optex::textconv` の `finalize` が `@ARGV` を Command::Run::Tmpfile の
  `path` に置き換える。そのため見出しが `/dev/fd/5` になる
  （`nup --textconv=plist x.plist c.txt` で確認した）。
- **Perl の open の仕組みだけでは、名前を保ったまま変換をはさめない**：
  PerlIO の `:via` 層はファイル名を受け取らない。`CORE::GLOBAL::open` は、
  差し替えた後にコンパイルされるコードにしか効かない。
- **`<>` は tie した ARGV で扱える**：`tie *ARGV` で、ファイルごとに変換後の
  データを読ませ、`$ARGV` に元の名前を入れられることを試した
  （`/private/tmp/claude-502/-Users-utashiro-Git-tecolicom/2e3b3500-e37d-4b08-b8ad-8c7c09bc6140/scratchpad/tieargv.pl`）。
- **Command::Run**（1.05）：外部コマンドとコードリファレンス
  （`[\&func, @args]`）を同じ形で実行し、出力を一時ファイルに保存して `path`
  （`/dev/fd/N`）とファイルハンドルで渡せる。Command::Run::Tmpfile を継承している。
- **skylighting 0.15.0.1**（Homebrew で入れた）：
  - pandoc の作者による。pandoc のハイライトもこれで、メンテナンスが続いている。
    言語の定義は KDE の構文定義から作られ、195 の言語に対応している。
  - 1 回あたり 0.021 秒（source-highlight は 0.006 秒、bat は 0.044 秒、
    pygmentize は 0.194 秒）。
  - ファイル名の拡張子から言語を判断する。`.txt` は色なしでそのまま出す。
    拡張子のないファイル（`#!/bin/bash` で始まるものも）は
    `No syntax specified` で終了コード 1 になる。
  - 既定のスタイル `kate` は白い背景も出力する。`-S pygments` は文字の色だけで、
    pandoc の既定と同じ。
  - `-C` を指定しないと、パイプの先でも RGB で出力する。`-C 16` で端末の基本
    16 色になる。
- source-highlight は 2019-10-12 の 3.1.9 以降、新しい版が出ていない。

## 決まっていること

### IO::Polarizer（新しい配布 IO-Polarizer）

- **置き場所**：`~/Git/tecolicom/IO-Polarizer`。ほかの tecolicom の配布と同じく
  Minilla で管理する。
- **変換の書き方は Command::Run にそろえる**：変換は、外部コマンドの配列
  （`['skylighting', '-f', 'ansi', ...]`）か、コードリファレンス
  （`[\&func, @args]`）。実行には Command::Run を使い、結果の一時ファイルを
  そのまま使う。
- **どのファイルに使うかは、ファイル名で選ぶ**：textconv の `@CONVERTER` と同じく、
  ファイル名に対する条件と変換を組にして登録する。
- **`open_input($file)`**：返すのは IO::File（IO::Handle の子クラス）。
  変換するファイルなら、変換後のデータの入った一時ファイルのハンドル
  （Command::Run::Tmpfile の `fh`、`new_tmpfile` で作られる IO::File）を返す。
  変換しないファイルも IO::File で開いて返し、どちらの場合も同じ型にする。
  返すハンドルは `:raw`。文字コードの層は、呼ぶ側が `binmode` で付ける
  （`use open` はレキシカルなので、IO::Polarizer の中の open には呼ぶ側の
  既定の層が付かないため）。変換しないファイル、変換に失敗したファイル
  （終了コードが 0 でない）なら、ふつうに open したハンドルを返す。
  標準入力（`-`）は変換しない。ファイル名は呼ぶ側が元のまま持っている。
- **ARGV を tie する機能**：`<>` で読むプログラムを、プログラムを変えずに対象に
  する。各ファイルに `open_input` を使い、`$ARGV` に元の名前を入れる。
  モジュールの `import` で ARGV を tie し、`@ARGV` は最初に読むときに取り出す。
  こうすると、`perl -MIO::Polarizer::... -ne ...` のワンライナーにも、
  Getopt::Long でオプションを取り除いてから `<>` で読むスクリプトにも効く。
  試作（`/private/tmp/claude-502/-Users-utashiro-Git-tecolicom/2e3b3500-e37d-4b08-b8ad-8c7c09bc6140/scratchpad/LazyArgv.pm`）で、
  `-n`、Getopt::Long の後、標準入力の 3 通りを確かめた。
  `$.`、`eof()`、`<<>>` の扱いは確かめていない。
- **変換をするモジュールは別に置く**：たとえば `IO::Polarizer::skylighting`。
  読み込まれたときに、自分の変換を登録する。

### IO::Polarizer::skylighting

- コマンドは `skylighting -f ansi -r -C 16 -S pygments ファイル名`。
- 言語は skylighting に拡張子から判断させる。判断できずに失敗したファイルは、
  `open_input` の規則どおり、元のまま読まれる。

### ansicolumn

- `read_files` の `open` を IO::Polarizer の `open_input` に置き換える。
  見出しの名前（`name => $file`）は元のまま。

### nup

- skylighting が入っていて、ファイルを渡したとき（コマンドの出力を見るときでは
  ないとき）、ansicolumn に IO::Polarizer::skylighting を使わせる。出力先
  （端末の less、PDF、`-o` のファイル、`--no-pager`）にかかわらず色を付ける。
- 止めるオプションは `--no-highlight`。

## 私（Claude）が決め、承認されたこと

- `-C 16`：端末の配色に合わせるため。less（source-highlight の `esc.style`）の
  色に近いかは比べていない。`--black-board` のような暗い背景で読めるかも
  確かめていない。
- `-S pygments`：背景を出さないため、また pandoc の既定と同じ色にするため。
- 止めるオプションの名前 `--no-highlight`。
- 出力先にかかわらず色を付けること。

- ESC を含むファイルは変換しない。skylighting は ESC と `[` を別々に色付けして
  既存の ANSI のシーケンスを壊すが、終了コードは 0 なので、失敗の規則では
  救えないため。`.txt` などで行ごとに `\e[0m\e[22;23;24m` が入るのは、
  見た目が変わらないので受け入れる。
- リリースの順序は IO-Polarizer、ansicolumn、nup。nup の cpanfile では、
  minilla-release の規則どおり、nup のリリースのときに新しい ansicolumn と
  IO::Polarizer を必須にする。

## 実装する人に任せること

- IO::Polarizer の関数名、登録の API の形（関数かクラスメソッドか、条件の書き方）。
- ARGV を tie する機能を、どの時点で有効にするか（オプションの解析が終わって
  `@ARGV` がファイルだけになった後でなければならない）。tie したときの `$.`、
  `eof` と `eof()` の扱い。
- ansicolumn から IO::Polarizer::skylighting をどう読み込ませるか
  （ansicolumn の `-M` は Getopt::EX のモジュールの仕組みで、
  `App::ansicolumn::` などの下を探す）。
- ansicolumn が IO::Polarizer を必須の依存にするか、入っていれば使う形にするか。
- テストの書き方。

## 速さの目安

ファイルごとに skylighting が 1 回起動するので、1 ファイルあたり約 0.02 秒増える。

## 実装で変わったこと（2026-11-16）

- **ansicolumn への渡し方は `--polarizer=NAME` オプション**：計画では
  `-MPolarizer::load=skylighting` を ansicolumn に渡すつもりだったが、optex は
  コマンド名の後の `-M` を、読み込めるかぎり自分のモジュールとして取ってしまう
  （`BASECLASS => ['', 'App::optex', 'Getopt::EX']`、`IGNORE_NO_MODULE`）。
  IO-Polarizer を入れた環境では `Getopt::EX::Polarizer` が optex に読み込まれ、
  ansicolumn に届かない。そのため ansicolumn に `--polarizer=NAME` を足し、
  nup は up.pm の `--highlight` を通じてこれを渡す。
- **`IO::Polarizer::load(@names)`**：名前から `IO::Polarizer::NAME` の `setup` を
  呼ぶ。`--polarizer` と `Getopt::EX::Polarizer::load` の両方がこれを使う。
- **`setup` と `import` を分けた**：`IO::Polarizer::skylighting` の `setup` は
  変換を登録するだけで、ARGV を tie するのは `use` / `-M` で読み込んだとき
  （`import`）だけ。ansicolumn の中では ARGV を tie しない。
- **skylighting の出力から余分なシーケンスを取り除く**：skylighting はリセットの
  たびに `\e[22;23;24m` を付ける。行末にシーケンスが 2 つ続くと、文字が幅ちょうどの
  行を Text::ANSI::Fold が折り返したとき、次に空行が 1 行入る。変換の中で
  `\e[0m` の後の `\e[22;23;24m` と、重なった `\e[0m` を取り除く。
- **IO::Polarizer はインストールしていない**：開発中の確認は `PERL5LIB` で行った。

### 残っている違い

- 色を付けると、折り返しの位置が変わる行がある（`int(` の `(` が次の行に送られる
  か、など）。Text::ANSI::Fold の禁則が、トークンの間のシーケンスをまたいで
  働かないため。up.pm と script/nup を 2 段で表示したとき、1519 行のうち 4 行。
- 変換の出力は Command::Run が UTF-8 として読む。UTF-8 でないファイルを変換すると、
  文字が化ける可能性がある。確かめていない。

## レビューを受けて変えたこと（2026-11-16）

- **変換は IO::Polarizer が自分で fork して実行する**：Command::Run の実行部分は
  使わず、Command::Run::Tmpfile の一時ファイルに、子プロセスの標準出力を直接
  つなぐ。Command::Run は出力を UTF-8 として読むので、UTF-8 でない出力が化け、
  警告が出ていた。標準エラーは capture をやめて捨てる（64KB を超えると止まって
  いた）。子は `POSIX::_exit` で終わるので、呼び出し側の END ブロックは走らず、
  eval の中で exec に失敗しても、子がプログラムの続きを実行しない。`$?` は保ち、
  SIGCHLD が無視されていても動く。変換の書き方（配列、最後にファイル名）は
  Command::Run と同じまま。
- **標準入力は STDIN そのものを返す**：dup したハンドルは、STDIN が先読みした
  分を読めなかった。
- **skylighting**：CR LF を分断しない。空のファイルと 256KB を超えるファイルは
  変換しない（`$IO::Polarizer::skylighting::MAX_SIZE`）。5.9MB のファイルで
  2.5 秒が 42 秒になっていた。
- **nup は IO::Polarizer がなければ `--polarizer` を付けない**：up.pm が @INC を
  探す。skylighting だけがある環境で、ファイル表示がすべてエラーになっていた。

### リリースのときに要ること

- nup の cpanfile で、`--polarizer` を持つ ansicolumn の版と IO::Polarizer を
  必須にする。古い ansicolumn に `--polarizer` を渡すと `Unknown option` になる。
- 順序は IO-Polarizer、ansicolumn、nup。

### 直していない指摘（軽いもの）

- tie した `<>` は `-C` や `use open` の層を見ない。`binmode ARGV` などの
  メソッド（BINMODE、GETC、READ、FILENO）もない。
- `-` で始まるファイル名は、変換のコマンドにオプションとして渡る（結果は色なし）。
- `--polarizer` を付けると、ansicolumn の 2 引数 open の動き（`'cmd |'`）が
  なくなる。nup は既定で付ける。
- 読み終えた後の `<>` は、素の perl と違い、STDIN を読まない。
- `--polarizer requires IO::Polarizer.` は、読み込みに失敗した本当の理由を出さない。
- nup → up.pm → 本物の ansicolumn → skylighting を通すテストはない。
