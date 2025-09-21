# OO Modulino 設計パターン

## 概要

OO Modulino (Object-Oriented Modulino) とは、Modulino に対して、その任意のメソッドを CLI 上のサブコマンドとして呼び出せるように、初期化とメソッド呼び出しの dispatcher を加えたものです。

## Modulino とは

Modulino は、モジュールが実行可能ファイルとしても動作する設計パターンです（[→参考](https://www.masteringperl.org/category/chapters/modulinos/)）。

一般的に、Modulino が CLI にどんな機能を提供するかについては、個々のプログラマーの自由裁量に任されています。従って、その CLI とは異なる任意の関数を CLI から使うには、結局スクリプトを書く必要があります。

## OO Modulino の特徴

OO Modulino は、Modulino の CLI に対して、
git などのサブコマンドを持った CLI を参考にして、
次のような一定の規約・約束事を導入したものです：

```
program [GLOBAL_OPTIONS] COMMAND [COMMAND_ARGS]
```

- `GLOBAL_OPTIONS`: コンストラクタに渡される（`--key=value` 形式）
- `COMMAND`: 呼び出すメソッド名
- `COMMAND_ARGS`: メソッドへの引数


Modulino の CLI にこの呼び出し規約を導入することで、
モジュールの任意のメソッドをコマンド行から簡単に試すことが可能になります。
モジュールの開発者も、後からそのモジュールを試す人にとっても、これは非常に
有益な特性です。

### git コマンドとの類似性

この設計は git コマンドに着想を得ています：

- `git --git-dir=/path commit -m "message"`
  - `--git-dir=/path`: グローバルオプション（git オブジェクトの設定）
  - `commit`: サブコマンド（メソッド）
  - `-m "message"`: コマンド引数

同様の考え方に基づいて、OO Modulino では、モジュールのメソッドやコンストラクタオプションをコマンド行から渡すことができます：

- `./MyScript.pm --config=prod query "SELECT * FROM users"`
  - `--config=prod`: コンストラクタオプション
  - `query`: メソッド名
  - `"SELECT * FROM users"`: メソッド引数


## 基本的な実装例

例として、Mouse で書かれたモジュールを OO Modulino にする方法を取り上げます。

### 元々のモジュール (Mouse ベース)

```perl
package Greetings;
use Mouse;

has name => (is => 'rw', default => 'world');

sub hello {
  my ($self, @msg) = @_; +{ result => ["Hello", $self->name, @msg] }
}

sub goodnight {
  my ($self, @msg) = @_; +{ result => ["Good night", $self->name, @msg] }
}
#========================================
1;
```

このモジュールを CLI から試すには、以下のようなワンライナーを書く必要があります：

```sh
% perl -I. -MGreetings -MJSON -le 'print encode_json(Greetings->new(name => "universe")->hello)'
{"result":["Hello","universe"]}
```

### OO Modulino 化（JSON対応）

前節の `Greetings.pm` を OO Modulino 化したモジュール `Greetings_oo_modulino_json.pm` を書いてみます。

```perl
#!/usr/bin/env perl
package Greetings_oo_modulino_json;

# ...省略...

use JSON;

# _parse_long_opts, _decode_json_maybe の実装は別掲

sub cmd_help {
  die "Usage: $0 [OPTIONS] COMMAND ARGS...\n";
}

unless (caller) {
  my $self = __PACKAGE__->new(__PACKAGE__->_parse_long_opts(\@ARGV));

  my $cmd = shift || "help";

  if (my $sub = $self->can("cmd_$cmd")) {
    $sub->($self, map {_decode_json_maybe($_)} @ARGV);
  }
  elsif ($sub = $self->can($cmd)) {
    print encode_json($sub->($self, map {_decode_json_maybe($_)} @ARGV)), "\n";
  }
  else {
    die "Unknown command: $cmd\n";
  }
}
1;
```

OO Modulino なら、簡単にメソッドを試すことができます。（もしシェルが Zsh で、[App::oo_modulino_zsh_completion_helper](https://metacpan.org/pod/App::oo_modulino_zsh_completion_helper)をインストールしていれば、メソッド名をタブで補完することも可能です）

```sh
% ./Greetings_oo_modulino_json.pm hello '{"foo":"bar"}'
{"result":["Hello","world",{"foo":"bar"}]}

% ./Greetings_oo_modulino_json.pm --name='["foo","bar"]' goodnight 
{"result":["Good night",["foo","bar"]]}
```

### 付録

```perl
sub _parse_long_opts {
  my ($class, $list) = @_;
  my @opts;
  while (@$list and $list->[0] =~ /^--(?:(\w+)(?:=(.*))?)?\z/s) {
    shift @$list;
    last unless defined $1;
    push @opts, $1, _decode_json_maybe($2) // 1;
  }
  @opts;
}

sub _decode_json_maybe {
  my ($str) = @_;
  if (not defined $str) {
    return undef;
  }
  elsif ($str =~ /^(?:\[.*?\]|\{.*?\})\z/s) {
    decode_json($str)
  }
  else {
    $str
  }
}
```


## まとめ

OO Modulino 設計パターンは、Perl モジュール開発において以下の利点を提供します：

- **即座のフィードバック**: メソッドを書いたらすぐ試せる
- **統一されたインターフェース**: 一貫した CLI 規約
- **テスタビリティの向上**: 小さな単位でのテストが容易
- **デバッグの容易さ**: 標準ツールがそのまま使える

これにより、開発の初期段階から本番運用まで、一貫した方法でモジュールを扱えます。

## 参考資料

- [Modulino: both script and module](https://perlmaven.com/modulino-both-script-and-module)
- [Mastering Perl: Modulinos](https://www.masteringperl.org/category/chapters/modulinos/)
- [MOP4Import::Base::CLI_JSON](../Base/CLI_JSON.pod)
- [App::oo_modulino_zsh_completion_helper](https://metacpan.org/pod/App::oo_modulino_zsh_completion_helper)
