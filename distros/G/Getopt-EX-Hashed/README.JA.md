# NAME

Getopt::EX::Hashed - Getopt::Long のためのハッシュオブジェクト自動化

# VERSION

Version 1.0602

# SYNOPSIS

    # script/foo
    use App::foo;
    App::foo->new->run();

    # lib/App/foo.pm
    package App::foo;

    use Getopt::EX::Hashed; {
        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );
        has start    => ' =i  s begin ' , default => 1;
        has end      => ' =i  e       ' ;
        has file     => ' =s@ f       ' , any => qr/^(?!\.)/;
        has score    => ' =i          ' , min => 0, max => 100;
        has answer   => ' =i          ' , must => sub { $_[1] == 42 };
        has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
        has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
    } no Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->answer == 42) {
            $app->question //= 'life';
            ...

# DESCRIPTION

**Getopt::EX::Hashed** は、**Getopt::Long** および **Getopt::EX::Long** を含む互換モジュール向けに、コマンドラインオプション値を格納するハッシュオブジェクトの作成を自動化するモジュールです。モジュール名は **Getopt::EX** プレフィックスを共有しますが、現時点では **Getopt::EX** 内の他のモジュールから独立して動作します。

このモジュールの主目的は、初期化と仕様の定義を一箇所に統合することです。簡易な検証インターフェースも提供します。

`is` パラメータが与えられるとアクセサメソッドが自動生成されます。同名の関数がすでに定義されている場合、プログラムは致命的エラーとなります。オブジェクトが破棄されるとアクセサは削除されます。同時に複数のオブジェクトが存在する場合、問題が発生する可能性があります。

# FUNCTION

## **has**

次の形式でオプションパラメータを宣言します。かっこは見やすさのためのもので、省略可能です。

    has option_name => ( param => value, ... );

例えば、整数値を引数に取るオプション `--number` を定義し、`-n` としても使えるようにするには、次のようにします。

    has number => spec => "=i n";

アクセサは最初の名前で作成されます。この例では、アクセサは `$app->number` として定義されます。

配列リファレンスを与えると、複数の名前を一度に宣言できます。

    has [ 'left', 'right' ] => ( spec => "=i" );

名前がプラス (`+`) で始まる場合、与えたパラメータは既存の設定を更新します。

    has '+left' => ( default => 1 );

`spec` パラメータについては、先頭のパラメータであればラベルを省略できます。

    has left => "=i", default => 1;

パラメータ数が奇数の場合、最初のパラメータは暗黙のラベルを持つものとして扱われます。コードリファレンスなら `action`、それ以外なら `spec` です。

利用可能なパラメータは以下の通りです。

- \[ **spec** => \] _string_

    オプション仕様を与えます。`spec =>` ラベルは最初のパラメータである場合に限り省略できます。

    _string_ では、オプション仕様とエイリアス名は空白で区切られ、順序は任意です。

    整数を値に取る `--start` というオプションを用意し、`-s` や `--begin` という名前でも使えるようにするには、次のように宣言します。

        has start => "=i s begin";

    上記の宣言は次の文字列にコンパイルされます。

        start|s|begin=i

    これは `Getopt::Long` の定義に準拠しています。もちろん、次のように書くこともできます:

        has start => "s|begin=i";

    名前やエイリアスにアンダースコア (`_`) が含まれている場合、アンダースコアをダッシュ (`-`) に置き換えた別のエイリアス名が定義されます。

        has a_to_z => "=s";

    上記の宣言は次の文字列にコンパイルされます。

        a_to_z|a-to-z=s

    オプション spec が不要な場合は、空文字列（または空白のみの文字列）を値として与えてください。spec 文字列がなければ、そのメンバーはオプションとして扱われません。

- **alias** => _string_

    追加のエイリアス名は **alias** パラメータでも指定できます。`spec` パラメータ内のものと違いはありません。

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    アクセサメソッドを生成するには、`is` パラメータが必要です。値は読み取り専用なら `ro`、読み書き可能なら `rw` を設定します。

    読み書き可能アクセサは lvalue 属性を持つため、代入できます。次のように使えます。

        $app->foo //= 1;

    これは以下のように書くよりもずっと簡単です。

        $app->foo(1) unless defined $app->foo;

    以降のすべてのメンバーにアクセサを作成したい場合は、`configure` で `DEFAULT` パラメータを設定してください。

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    代入可能なアクセサが好きでない場合は、`ACCESSOR_LVALUE` パラメータを 0 に設定してください。アクセサは `new` の時点で生成されるため、この値はすべてのメンバーに対して有効です。

- **default** => _value_ | _coderef_

    デフォルト値を設定します。デフォルトが与えられない場合、メンバーは `undef` として初期化されます。

    値が ARRAY または HASH へのリファレンスである場合、各 `new` 呼び出しで浅いコピーが作成されます。これは、リファレンス自体はコピーされますが、内容は共有されることを意味します。配列やハッシュの内容を変更すると、すべてのインスタンスに影響します。

    コードリファレンスが与えられた場合、**new** の時点で呼び出され、デフォルト値を取得します。これは、宣言時ではなく実行時に値を評価したい場合に有効です。デフォルトのアクションを定義したい場合は **action** パラメータを使用してください。コードリファレンス自体を初期値として設定したい場合は、コードリファレンスを返すコードリファレンスを指定する必要があります。

    SCALAR へのリファレンスが与えられた場合、オプション値はハッシュオブジェクトのメンバーではなく、そのリファレンスが指すデータに保存されます。この場合、ハッシュメンバーにアクセスしても期待する値は得られません。

- \[ **action** => \] _coderef_

    パラメータ `action` はオプションを処理するために呼び出されるコードリファレンスを受け取ります。`action =>` ラベルは、最初のパラメータである場合に限り省略できます。

    呼び出し時には、ハッシュオブジェクトが `$_` として渡されます。

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    `"<>"` を使って非オプション引数を処理できます。この場合、spec パラメータは重要ではなく、必須でもありません。

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

以下のパラメータはすべてデータ検証用です。まず `must` は汎用バリデータで、あらゆることを実装できます。他は一般的なルールのためのショートカットです。

- **must** => _coderef_ | \[ _coderef_ ... \]

    パラメータ `must` はオプション値を検証するコードリファレンスを受け取ります。引数は `action` と同じで、真偽値を返します。次の例では、オプション **--answer** は有効な値として 42 のみを受け付けます。

        has answer => '=i',
            must => sub { $_[1] == 42 };

    複数のコードリファレンスが与えられた場合、すべてのコードが真を返さなければなりません。

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    引数の最小値と最大値の制限を設定します。

- **any** => _arrayref_ | qr/_regex_/ | _coderef_

    有効な文字列パラメータのリストを設定します。各項目は文字列、正規表現リファレンス、またはコードリファレンスにできます。引数が、与えられたリストのいずれかの項目と同一、または一致する場合に有効です。値が arrayref でない場合は、単一項目のリスト（通常は regexpref か coderef）として扱われます。

    以下の宣言はほぼ同等ですが、2 つ目は大文字小文字を区別しません。

        has question => '=s',
            any => [ 'life', 'universe', 'everything' ];

        has question => '=s',
            any => qr/^(life|universe|everything)$/i;

    オプション引数を使用している場合は、デフォルト値をリストに含めるのを忘れないでください。そうしないと検証エラーになります。

        has question => ':s',
            any => [ 'life', 'universe', 'everything', '' ];

# METHOD

## **new**

新しいハッシュオブジェクトを作成するクラスメソッド。すべてのメンバーをデフォルト値で初期化し、設定に従ってアクセサメソッドを作成します。bless されたハッシュリファレンスを返します。LOCK\_KEYS が有効な場合、ハッシュキーはロックされます。

## **optspec**

`GetOptions` 関数に渡すことができるオプション仕様のリストを返します。

    GetOptions($obj->optspec)

`GetOptions` は、最初の引数としてハッシュリファレンスを与えることで値をハッシュに格納する機能を持ちますが、必須ではありません。

## **getopt** \[ _arrayref_ \]

オプションを処理するために、呼び出し元のコンテキストで定義された適切な関数を呼び出します。

    $obj->getopt

    $obj->getopt(\@argv);

上記の例は、以下のコードに対するショートカットです。

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

LOCK\_KEYS が有効なとき、存在しないメンバーへのアクセスはエラーになります。アクセス前に新しいメンバーキーを宣言するにはこのメソッドを使用してください。

    $obj->use_keys( qw(foo bar) );

任意のキーにアクセスしたい場合は、オブジェクトのロックを解除してください。

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

この挙動は `configure` の `LOCK_KEYS` パラメータで変更できます。

## **configure** **label** => _value_, ...

オブジェクト作成前にクラスメソッド `Getopt::EX::Hashed->configure()` を使用してください。この情報は呼び出し元パッケージごとに個別に保存されます。`new()` 呼び出し後、パッケージレベルの設定がオブジェクトにコピーされて使用されます。オブジェクトレベルの設定を更新するには `$obj->configure()` を使用します。

利用可能な設定パラメータは次のとおりです。

- **LOCK\_KEYS** (default: 1)

    ハッシュキーをロックします。これによりタイプミスなどで意図しないハッシュエントリが作成されるのを防ぎます。

- **REPLACE\_UNDERSCORE** (default: 1)

    アンダースコアをダッシュに置き換えたオプションのエイリアスを自動的に作成します。

- **REMOVE\_UNDERSCORE** (default: 0)

    アンダースコアを削除したオプションのエイリアスを自動的に作成します。

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    `getopt` メソッドから呼び出される関数名を設定します。

- **ACCESSOR\_PREFIX** (default: '')

    指定された場合、メンバー名の前に付加してアクセサメソッドを作成します。`ACCESSOR_PREFIX` が `opt_` と定義されていると、メンバー `file` のアクセサは `opt_file` になります。

- **ACCESSOR\_LVALUE** (default: 1)

    真の場合、読み書きアクセサに lvalue 属性が付きます。その挙動が好みでない場合は 0 に設定してください。

- **DEFAULT**

    デフォルトパラメータを設定します。`has` が呼ばれると、DEFAULT パラメータは明示的なパラメータの前に挿入されます。両方に同じパラメータがある場合は、明示的なものが優先されます。`+` を用いる増分呼び出しには影響しません。

    DEFAULT の典型的な使い方は、以降のすべてのハッシュエントリに対するアクセサメソッドを用意するための `is` です。リセットするには `DEFAULT => []` を宣言してください。

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

クラスを元の状態にリセットします。

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ALong)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2025 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
