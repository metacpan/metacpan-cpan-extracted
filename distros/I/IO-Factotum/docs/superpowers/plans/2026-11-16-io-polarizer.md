# IO::Polarizer 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `nup *.c` で、skylighting が入っていれば各ファイルにシンタックスハイライトが付き、見出しには元のファイル名が出るようにする。

**Architecture:** 新しい配布 IO-Polarizer が、ファイル名に応じて変換コマンドを Command::Run で実行し、結果の一時ファイルを IO::File として返す（`open_input`）。`<>` 用に ARGV を tie する機能も持つ。ansicolumn は IO::Polarizer が読み込まれていればそれでファイルを開き、nup は skylighting があれば ansicolumn に `-MPolarizer::load=skylighting` を渡す。

**Tech Stack:** Perl 5.16+, Minilla, Command::Run 1.05, Getopt::EX 3.05, skylighting 0.15, bash（nup）

**Spec:** `/Users/utashiro/Git/tecolicom/IO-Polarizer/docs/superpowers/specs/2026-11-16-io-polarizer-design.md`

## Global Constraints

- 3 つのリポジトリにまたがる：
  - `~/Git/tecolicom/IO-Polarizer`（新規、Minilla）
  - `~/Git/tecolicom/ANSI-Tools/App-ansicolumn`
  - `~/Git/tecolicom/App-nup`
- Perl の最低版は `v5.16`（ansicolumn と同じ）。
- 変換の書き方は Command::Run の command と同じ：外部コマンドの配列、または `[\&code, @args]`。ファイル名は最後の引数として足す。シェルは通さない。
- skylighting のコマンドは、正確に `skylighting -f ansi -r -C 16 -S pygments ファイル名`。
- nup の止めるオプションは `--no-highlight`。
- 変換の終了コードが 0 でなければ、元のファイルをそのまま読む。元のファイルは書き換えない。
- skylighting が入っていない環境で、nup の出力を変えない。
- コミットメッセージに `Claude-Session:` 行を入れない。`Co-Authored-By:` は付ける。
- Changes はコミットしない。cpanfile の依存の引き上げもリリースのときまでコミットしない（minilla-release の規則）。CPAN へのリリースはこの計画に含めない。

## Review Focus

1. **空白を含むファイル名**（`a b.c`）：シェルを通さないので、そのまま変換されるはず → Task 1 のテスト `open_input: file name with a space`。
2. **存在しないファイル**：`open_input` は undef を返して `$!` を設定し、ansicolumn はこれまでと同じ `FILE: No such file or directory` で止まるはず → Task 1 のテスト `open_input: missing file`。
3. **標準入力 `-`**：変換せず、そのまま読めるはず → Task 1 のテスト `open_input: stdin`。
4. **すでに ANSI のシーケンスを含むファイル**：skylighting に通さず、そのまま表示されるはず → Task 3 のテスト `skylighting: file with ESC`。
5. **拡張子のないファイル**（`#!/bin/bash` で始まるスクリプトを含む）：skylighting は失敗するので、色なしでそのまま表示されるはず → Task 3 のテスト `skylighting: no extension`。

---

### Task 1: IO::Polarizer の配布と `open_input`

**Files:**
- Create: `IO-Polarizer/lib/IO/Polarizer.pm`
- Create: `IO-Polarizer/cpanfile`（`requires 'perl', 'v5.16'; requires 'Command::Run', '1.05';`、test に `Test::More 0.98`）
- Create: `IO-Polarizer/Changes`、`IO-Polarizer/.gitignore`、`IO-Polarizer/minil.toml`、`IO-Polarizer/t/00_compile.t`（ほかの tecolicom の Minilla 配布にならう。たとえば `~/Git/tecolicom/Command-Run`）
- Test: `IO-Polarizer/t/01_open_input.t`

**Interfaces:**
- Produces:
  - `IO::Polarizer::register(match => Regexp|CODE, command => ARRAY)`：変換を末尾に足す。`match` が Regexp ならファイル名に当て、CODE なら `$code->($file)` が真のときに使う。
  - `IO::Polarizer::clear()`：登録をすべて消す（テスト用）。
  - `IO::Polarizer::open_input($file) -> IO::File | undef`：最初に `match` した変換を `Command::Run->new(command => [@$command, $file])->update` で実行する。`result->{result} == 0` なら一時ファイルを rewind したハンドル、そうでなければ（または match しなければ）`IO::File->new($file, '<')` を返す。`$file eq '-'` なら変換せず STDIN を返す。返すハンドルは `:raw`。開けなければ undef（`$!` はそのまま）。

- [ ] **Step 1: `git init` し、Minilla の配布の骨組みを作る**（既存の `docs/` は残す）。`minil build` が通ることを確かめる。

- [ ] **Step 2: 失敗するテストを書く** `t/01_open_input.t`。テスト用ファイルは `File::Temp` の一時ディレクトリに作る。

```perl
# register an uppercasing converter for .up files
IO::Polarizer::register(match => qr/\.up$/, command => ['perl', '-pe', '$_ = uc']);

# subtest 'open_input: converted'
is slurp(IO::Polarizer::open_input("$dir/a.up")), "HELLO\n";
isa_ok IO::Polarizer::open_input("$dir/a.up"), 'IO::File';
# subtest 'open_input: not matched'
is slurp(IO::Polarizer::open_input("$dir/a.txt")), "hello\n";
# subtest 'open_input: converter fails'
IO::Polarizer::clear();
IO::Polarizer::register(match => qr/\.up$/, command => ['false']);
is slurp(IO::Polarizer::open_input("$dir/a.up")), "hello\n";
# subtest 'open_input: code reference'
IO::Polarizer::clear();
IO::Polarizer::register(match => sub { $_[0] =~ /\.up$/ },
                        command => [sub { open my $f, '<', $_[-1]; print scalar reverse <$f> }]);
is slurp(IO::Polarizer::open_input("$dir/a.up")), "\nolleh";
# subtest 'open_input: file name with a space'  ("$dir/a b.up" contains "hello\n")
is slurp(IO::Polarizer::open_input("$dir/a b.up")), "HELLO\n";   # with the uppercasing converter
# subtest 'open_input: missing file'
ok !defined IO::Polarizer::open_input("$dir/none.txt");
ok $!{ENOENT};
# subtest 'open_input: stdin'  (run in a child: echo hello | perl -Ilib -MIO::Polarizer -e '...')
is $child_output, "hello\n";
```

- [ ] **Step 3: テストが失敗することを確かめる**
  Run: `prove -l t/01_open_input.t`
  Expected: FAIL（`Can't locate IO/Polarizer.pm` など）

- [ ] **Step 4: `lib/IO/Polarizer.pm` に `register`、`clear`、`open_input` を実装する。** POD に、目的（偏光フィルターのように、元のファイルを変えずに読むときだけ変換する）、関数、変換の書き方を書く。

- [ ] **Step 5: テストが通ることを確かめる**
  Run: `prove -lr t`
  Expected: PASS

- [ ] **Step 6: `minil build` してコミットする**

```bash
git add -A && git commit -m "IO::Polarizer: open_input with registered converters"
```

### Task 2: ARGV を tie して `<>` に変換を効かせる

**Files:**
- Modify: `IO-Polarizer/lib/IO/Polarizer.pm`
- Create: `IO-Polarizer/lib/IO/Polarizer/ARGV.pm`（tie のクラス）
- Test: `IO-Polarizer/t/02_argv.t`

**Interfaces:**
- Consumes: `open_input($file)`
- Produces: `IO::Polarizer::tie_argv()`：`*ARGV` を `IO::Polarizer::ARGV` に tie する。二度呼んでも一度だけ tie する。`@ARGV` は最初に読むときに取り出し、空なら `-` とする。各ファイルを `open_input` で開き、`$ARGV` に元の名前を入れる。

試作は `/private/tmp/claude-502/-Users-utashiro-Git-tecolicom/2e3b3500-e37d-4b08-b8ad-8c7c09bc6140/scratchpad/LazyArgv.pm`（READLINE、EOF、`@ARGV` を遅れて取り出す処理）。

- [ ] **Step 1: 失敗するテストを書く** `t/02_argv.t`。子プロセスで `perl -Ilib -MIO::Polarizer -e 'IO::Polarizer::register(match => qr/./, command => [qw(perl -pe), q($_ = uc)]); IO::Polarizer::tie_argv(); ...' -- ARGS` を実行し、出力を比べる。f1 は `one\ntwo\n`、f2 は `three\n`。

```perl
# 'argv: while (<>)'        while (<>) { print "$ARGV: $_" }   f1 f2
is $out, "f1: ONE\nf1: TWO\nf2: THREE\n";
# 'argv: after Getopt::Long'  GetOptions("x" => \$x); print "x=$x\n"; while (<>) {...}   -- -x f1 f2
is $out, "x=1\nf1: ONE\nf1: TWO\nf2: THREE\n";
# 'argv: stdin'               echo four | ... while (<>) {...}
is $out, "-: FOUR\n";
# 'argv: list context'        print scalar(my @l = <>)   f1 f2
is $out, "3";
# 'argv: line numbers'        while (<>) { print "$.:$_" }   f1 f2   (continuous, as plain <>)
is $out, "1:ONE\n2:TWO\n3:THREE\n";
# 'argv: eof()'               while (<>) { print eof() ? "last\n" : "" }   f1 f2
is $out, "last\n";
```

- [ ] **Step 2: テストが失敗することを確かめる**
  Run: `prove -l t/02_argv.t`
  Expected: FAIL（`tie_argv` が未定義）

- [ ] **Step 3: `IO::Polarizer::ARGV`（TIEHANDLE、READLINE、EOF）と `tie_argv` を実装する。** `$.` は通しの行数を自分で数えて設定する。EOF は perltie のとおり、第 2 引数が 2（`eof()`）なら最後のファイルの終わりでだけ真を返す。

- [ ] **Step 4: テストが通ることを確かめる**
  Run: `prove -lr t`
  Expected: PASS

- [ ] **Step 5: `minil build` してコミットする**

```bash
git add -A && git commit -m "IO::Polarizer: tie ARGV so that <> reads converted files"
```

### Task 3: skylighting の変換と、Getopt::EX から読み込む口

**Files:**
- Create: `IO-Polarizer/lib/IO/Polarizer/skylighting.pm`
- Create: `IO-Polarizer/lib/Getopt/EX/Polarizer.pm`
- Test: `IO-Polarizer/t/03_skylighting.t`

**Interfaces:**
- Consumes: `register`、`tie_argv`
- Produces:
  - `IO::Polarizer::skylighting`：`import` のときに、次の変換を登録し、`tie_argv` を呼ぶ。
    - `match`：`$file ne '-'` で、ふつうのファイルで、中身に ESC（`\e`）を含まないとき
    - `command`：`['skylighting', '-f', 'ansi', '-r', '-C', '16', '-S', 'pygments']`
  - `Getopt::EX::Polarizer::load(NAME => 1, ...)`：各 NAME について `IO::Polarizer::NAME` を require して import する。引数の形は `App::optex::textconv::load` と同じ（名前と値の組）。使い方は `-MPolarizer::load=skylighting`。

- [ ] **Step 1: 失敗するテストを書く** `t/03_skylighting.t`。`skylighting` が PATH になければ `plan skip_all`。

```perl
# 'skylighting: C source'   a.c = "int x = 1;\n"
like slurp(open_input("$dir/a.c")), qr/\e\[/;
# 'skylighting: file with ESC'   e.c = "\e[31mred\e[m\n"
is slurp(open_input("$dir/e.c")), "\e[31mred\e[m\n";
# 'skylighting: no extension'    noext = "#!/bin/bash\necho\n"
is slurp(open_input("$dir/noext")), "#!/bin/bash\necho\n";
# 'Getopt::EX::Polarizer: load'  (child) perl -Ilib -MGetopt::EX::Polarizer -e 'Getopt::EX::Polarizer::load(skylighting => 1); print IO::Polarizer::open_input(shift)->getlines' a.c
like $out, qr/\e\[/;
```

- [ ] **Step 2: テストが失敗することを確かめる**
  Run: `prove -l t/03_skylighting.t`
  Expected: FAIL

- [ ] **Step 3: `IO::Polarizer::skylighting` と `Getopt::EX::Polarizer` を実装する。** POD に、skylighting の入手方法（`brew install skylighting`）と、`-S pygments`、`-C 16` を選んだ理由を書く。

- [ ] **Step 4: テストが通ることを確かめる**
  Run: `prove -lr t`
  Expected: PASS

- [ ] **Step 5: `minil build` してコミットする**

```bash
git add -A && git commit -m "IO::Polarizer::skylighting and Getopt::EX::Polarizer"
```

- [ ] **Step 6: 手元にインストールする**（Task 4 と 5 で使う）
  Run: `cpanm --notest .`（またはプロジェクトでふだん使っている方法）
  Expected: `perl -MIO::Polarizer -e1` が通る

### Task 4: ansicolumn が IO::Polarizer でファイルを開く

**Files:**
- Modify: `ANSI-Tools/App-ansicolumn/lib/App/ansicolumn.pm:394-419`（`read_files`）
- Test: `ANSI-Tools/App-ansicolumn/t/07_polarizer.t`

**Interfaces:**
- Consumes: `IO::Polarizer::open_input($file)`
- Produces: `IO::Polarizer->can('open_input')` が真なら、`read_files` はそれでファイルを開き、`binmode $fh, ':utf8'`（いまの `use open IO => 'utf8'` と同じ層）を付ける。偽ならいまのまま `open my $fh, $file`。どちらも開けなければ `die "$file: $!"`。IO::Polarizer は cpanfile に足さない（入っていれば使う）。

- [ ] **Step 1: 失敗するテストを書く** `t/07_polarizer.t`。IO::Polarizer がなければ `plan skip_all`。`$ENV{HOME}` は `t/home`。子プロセスで次を実行する。

```perl
# perl -Ilib -MIO::Polarizer -e 'IO::Polarizer::register(match => qr/./, command => [qw(perl -pe), q($_ = uc)]); require App::ansicolumn; exit App::ansicolumn::ansicolumn(@ARGV)' -- -V --filename f1 f2
# 'polarizer: converted'
like $out, qr/ONE/;
# 'polarizer: header keeps the name'
like $out, qr/: .*f1/;  unlike $out, qr{/dev/fd/};
```

- [ ] **Step 2: テストが失敗することを確かめる**
  Run: `prove -lv t/07_polarizer.t`
  Expected: FAIL（`ONE` が出ない）

- [ ] **Step 3: `read_files` を変える。**

- [ ] **Step 4: テストが通ることを確かめる**
  Run: `prove -lr t`
  Expected: PASS（158 + 新しいテスト）

- [ ] **Step 5: `minil build` してコミットする**

```bash
git add -A && git commit -m "Open files through IO::Polarizer when it is loaded"
```

### Task 5: nup が skylighting を自動で使う

**Files:**
- Modify: `App-nup/lib/App/optex/up.pm:536-538`（ansicolumn に足すオプションの位置）
- Modify: `App-nup/script/nup`（`OPTS` に `highlight`、ファイル表示のときの `target`、POD）
- Test: `App-nup/t/01_nup.t`、`App-nup/t/03_up_run.t`

**Interfaces:**
- Consumes: `-MPolarizer::load=skylighting`（Task 3）、ansicolumn の Task 4
- Produces:
  - up.pm：ansicolumn の既定のオプションを、`ansicolumn` の直後ではなく、先頭に続く `-M...` の引数の後に入れる。Getopt::EX は、引数の先頭にある `-M` しかモジュールとして読まないため（`Getopt::EX::Loader` の `parseopt` のループ）。
  - nup：`OPTS` に `[ highlight | # syntax highlight ]=1` を足す。ファイル表示のとき、`highlight` が真で `command -v skylighting` が成り立てば、`target=(ansicolumn -MPolarizer::load=skylighting "$@")`。コマンド表示のときは何もしない。

- [ ] **Step 1: 失敗するテストを書く**

```perl
# t/03_up_run.t  'module before the default options'
# optex -Mup --no-pager -- ansicolumn -Mdefault cpanfile   (App::ansicolumn::default exists)
is $status, 0;

# t/01_nup.t  (dry run -n; PATH has a directory with an executable dummy "skylighting")
# 'highlight: with skylighting'
like nup('script/nup'), qr/ansicolumn -MPolarizer::load=skylighting script\/nup/;
# 'highlight: --no-highlight'
unlike nup('--no-highlight script/nup'), qr/Polarizer/;
# 'highlight: without skylighting'  (PATH without the dummy)
unlike $out, qr/Polarizer/;
# 'highlight: command mode'
unlike nup('-e echo hello'), qr/Polarizer/;
```

- [ ] **Step 2: テストが失敗することを確かめる**
  Run: `prove -lr t`
  Expected: 上の 5 つが FAIL

- [ ] **Step 3: up.pm の挿入位置を変え、nup に `highlight` を足す。** nup の POD に `--no-highlight` の項目を足し、usage の一覧にも載せる。skylighting が要ること、`brew install skylighting` で入ることを書く。

- [ ] **Step 4: テストが通ることを確かめる**
  Run: `prove -lr t`
  Expected: PASS

- [ ] **Step 5: 実際に表示して確かめる**
  Run: `nup lib/App/optex/up.pm script/nup`
  Expected: `up.pm` に色が付き、`script/nup`（拡張子なし）は色なし。見出しは両方とも元の名前。

- [ ] **Step 6: `minil build` してコミットする**

```bash
git add -A && git commit -m "Highlight files with skylighting through IO::Polarizer"
```
